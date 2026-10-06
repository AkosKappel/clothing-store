# Script for populating the database. You can run it as: `mix run priv/repo/seeds.exs`
#
# The nightly demo reset runs it inside one transaction, so it must stay fast.

alias ClothingStore.Repo
alias ClothingStore.Transactions.Transaction
alias ClothingStore.Products.ProductTransaction
alias ClothingStore.Products
alias ClothingStore.Users

# Photos: Pexels (pexels.com/license), resized and converted to WebP in
# priv/static/images/products/<slug>.webp.
# {slug, title, category, price, stock, tags, description}
catalogue = [
  {"white-t-shirt", "Organic Cotton T-Shirt", "Shirts & Tops", "19.90", 42,
   ["popular", "eco-friendly"],
   "A soft crew-neck T-shirt in heavyweight organic cotton. Holds its shape wash after wash."},
  {"striped-shirt", "Striped Pocket T-Shirt", "Shirts & Tops", "34.90", 18, ["popular"],
   "White cotton T-shirt with navy stripes and a contrast chest pocket."},
  {"oxford-shirt", "Oxford Button-Down Shirt", "Shirts & Tops", "49.90", 12, [],
   "Light blue Oxford cloth with a button-down collar. Smart enough for the office, relaxed enough for weekends."},
  {"linen-shirt", "Linen Summer Shirt", "Shirts & Tops", "54.90", 3, ["summer", "new"],
   "A crisp white linen-blend shirt with a relaxed fit, made for warm days."},
  {"flannel-shirt", "Checked Flannel Shirt", "Shirts & Tops", "44.90", 0, ["winter"],
   "Brushed cotton flannel in a red and black check, warm enough to wear as a light jacket."},
  {"polo-shirt", "Zip Polo Shirt", "Shirts & Tops", "29.90", 25, ["summer"],
   "A sky blue stretch polo with a short zip placket and a slim fit."},
  {"slim-jeans", "Slim Fit Jeans", "Trousers", "79.90", 30, ["popular"],
   "Mid-rise slim jeans in stretch denim with a classic five-pocket design."},
  {"chinos", "Stretch Chinos", "Trousers", "59.90", 14, [],
   "Tan cotton chinos with a touch of stretch and a tapered leg."},
  {"cargo-trousers", "Cargo Trousers", "Trousers", "64.90", 4, ["new"],
   "Baggy olive cargo trousers in durable cotton twill with roomy side pockets."},
  {"denim-shorts", "Denim Shorts", "Trousers", "34.90", 20, ["summer", "sale"],
   "Mid-length denim shorts with rolled hems, cut from recycled cotton."},
  {"floral-dress", "Floral Print Dress", "Dresses & Skirts", "69.90", 9, ["summer", "popular"],
   "A knee-length dress in a dark floral print with long sleeves."},
  {"little-black-dress", "Little Black Dress", "Dresses & Skirts", "89.90", 6, [],
   "A black halter dress with an asymmetric hem. Dress it up or down."},
  {"running-shoes", "Running Shoes", "Shoes", "119.90", 10, ["popular"],
   "Lightweight white running shoes with a cushioned sole and a breathable mesh upper."},
  {"chelsea-boots", "Chelsea Boots", "Shoes", "159.00", 5, ["winter"],
   "Brown leather Chelsea boots with elastic side panels and a gum rubber sole."},
  {"loafers", "Chunky Loafers", "Shoes", "109.00", 1, ["new"],
   "Tan leather loafers on a chunky lug sole, with a snake-print strap."},
  {"sandals", "Leather Sandals", "Shoes", "59.90", 13, ["summer", "sale"],
   "Black leather sandals with buckled straps and a cushioned footbed."},
  {"sunglasses", "Classic Sunglasses", "Accessories", "39.90", 27, ["summer", "popular"],
   "Oval sunglasses with clear frames and dark UV400 lenses."},
  {"leather-belt", "Leather Belt", "Accessories", "34.90", 19, [],
   "Brown full-grain leather belt with a gold-tone buckle."},
  {"beanie", "Knitted Beanie", "Accessories", "19.90", 40, ["winter"],
   "A warm rib-knit beanie in soft wool blend."},
  {"tote-bag", "Canvas Tote Bag", "Accessories", "24.90", 31, ["eco-friendly"],
   "A sturdy organic canvas tote, big enough for a laptop and groceries."},
  {"wristwatch", "Minimalist Watch", "Accessories", "129.00", 7, ["new"],
   "A slim watch with a white dial, rose gold case and brown leather strap."},
  {"scarf", "Wool Scarf", "Accessories", "29.90", 0, ["winter", "sale"],
   "A generous scarf in soft grey wool."},
  {"leggings", "Training Leggings", "Sportswear", "44.90", 18, ["popular"],
   "High-waisted leggings in a squat-proof, quick-drying fabric."},
  {"track-jacket", "Track Jacket", "Sportswear", "69.90", 9, [],
   "A light grey zip-up track jacket with striped sleeves."}
]

for {slug, title, category, price, stock, tags, description} <- catalogue do
  {:ok, _} =
    Products.create_product(%{
      title: title,
      description: description,
      category: category,
      photo: "/images/products/#{slug}.webp",
      price: Decimal.new(price),
      stock: stock,
      tags: tags
    })
end

# A year of sales. A fixed random seed makes every reset produce the same pattern;
# the dates count back from now, so this month and last month always have sales.
:rand.seed(:exsss, {2026, 10, 6})
now = DateTime.utc_now(:second)
products = Products.list_products()

# popular products sell about three times as often
weighted =
  Enum.flat_map(products, fn product ->
    List.duplicate(product, if("popular" in product.tags, do: 3, else: 1))
  end)

# always one sale right now, so even on the 1st this month has one
sales =
  for days_ago <- 364..0//-1, days_ago == 0 or :rand.uniform() < 0.55 do
    offset = if days_ago == 0, do: 0, else: days_ago * 86_400 + :rand.uniform(36_000)
    at = DateTime.add(now, -offset, :second)

    items =
      weighted
      |> Enum.take_random(:rand.uniform(3))
      |> Enum.uniq_by(& &1.id)
      |> Enum.map(&{&1, :rand.uniform(2)})

    {at, items}
  end

{_count, transactions} =
  Repo.insert_all(
    Transaction,
    for {at, items} <- sales do
      total =
        Enum.reduce(items, Decimal.new(0), fn {product, quantity}, sum ->
          Decimal.add(sum, Decimal.mult(product.price, quantity))
        end)

      %{total_price: total, inserted_at: at, updated_at: at}
    end,
    returning: [:id]
  )

Repo.insert_all(
  ProductTransaction,
  for {%{id: transaction_id}, {at, items}} <- Enum.zip(transactions, sales),
      {product, quantity} <- items do
    %{
      transaction_id: transaction_id,
      product_id: product.id,
      quantity: quantity,
      unit_price: product.price,
      inserted_at: at,
      updated_at: at
    }
  end
)

# Demo account (ADMIN_EMAIL / ADMIN_PASSWORD), used by "Try the demo"
%{email: email, password: password} = ClothingStore.Demo.account()
{:ok, user} = Users.register_user(%{email: email, password: password})
# confirmed, so /users/confirm answers "already confirmed" instead of minting tokens
user |> Users.User.confirm_changeset() |> Repo.update!()
