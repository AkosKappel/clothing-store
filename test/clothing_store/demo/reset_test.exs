defmodule ClothingStore.Demo.ResetTest do
  # TRUNCATE is transactional in Postgres, so the sandbox rolls it back; async: false
  # because it locks every table the other tests use.
  use ClothingStore.DataCase, async: false

  alias ClothingStore.{Demo, Products, Repo, Users}
  import ClothingStore.ProductsFixtures
  import ClothingStore.UsersFixtures

  test "wipes visitor changes, reseeds and notifies live views" do
    product_fixture(%{title: "Visitor product"})
    Phoenix.PubSub.subscribe(ClothingStore.PubSub, "products")

    assert :ok = Demo.Reset.run()

    titles = Enum.map(Products.list_products(), & &1.title)
    refute "Visitor product" in titles
    assert "Organic Cotton T-Shirt" in titles
    assert length(titles) >= 20
    assert Users.get_user_by_email(Demo.account().email)

    # a year of sales, including this month and last month
    this_month = Date.utc_today() |> Date.beginning_of_month() |> Date.to_string()
    last_month = Date.utc_today() |> Date.beginning_of_month() |> Date.add(-1) |> Date.to_string()
    assert Repo.aggregate(ClothingStore.Transactions.Transaction, :count) > 150
    assert ClothingStore.Transactions.list_bestsellers_per_month(3, this_month) != []
    assert ClothingStore.Transactions.list_bestsellers_per_month(3, last_month) != []
    assert_receive :demo_reset
  end

  test "seeds a confirmed demo account, so confirmation requests insert no tokens" do
    assert :ok = Demo.Reset.run()

    user = Users.get_user_by_email(Demo.account().email)
    assert user.confirmed_at

    assert {:error, :already_confirmed} =
             Users.deliver_user_confirmation_instructions(user, &"/users/confirm/#{&1}")

    assert Repo.aggregate(ClothingStore.Users.UserToken, :count) == 0
  end

  test "disconnects live sessions" do
    token = Users.generate_user_session_token(user_fixture())
    ClothingStoreWeb.Endpoint.subscribe("users_sessions:" <> Base.url_encode64(token))

    assert :ok = Demo.Reset.run()

    assert_receive %Phoenix.Socket.Broadcast{event: "disconnect"}
  end

  test "a failing seed rolls everything back" do
    product_fixture(%{title: "Visitor product"})

    seeds =
      Path.join(System.tmp_dir!(), "failing_seeds_#{System.unique_integer([:positive])}.exs")

    File.write!(seeds, "raise \"seed failed\"")
    on_exit(fn -> File.rm(seeds) end)
    Phoenix.PubSub.subscribe(ClothingStore.PubSub, "products")

    assert_raise RuntimeError, "seed failed", fn -> Demo.Reset.run(seeds) end

    assert "Visitor product" in Enum.map(Products.list_products(), & &1.title)
    refute_receive :demo_reset
  end

  test "seeds the owner account as an admin when one is configured, and only then" do
    assert :ok = Demo.Reset.run()
    assert [%{role: "demo"}] = ClothingStore.Repo.all(ClothingStore.Users.User)

    demo = Application.fetch_env!(:clothing_store, :demo)
    on_exit(fn -> Application.put_env(:clothing_store, :demo, demo) end)

    Application.put_env(
      :clothing_store,
      :demo,
      Keyword.put(demo, :owner, email: "owner@example.com", password: "a long owner password")
    )

    assert :ok = Demo.Reset.run()
    owner = Users.get_user_by_email_and_password("owner@example.com", "a long owner password")
    assert %{role: "admin", confirmed_at: %DateTime{}} = owner
    assert %{role: "demo"} = Users.get_user_by_email(Demo.account().email)
  end
end
