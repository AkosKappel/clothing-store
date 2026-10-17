# Script for populating the database. You can run it as: `mix run priv/repo/seeds.exs`
#
# The nightly demo reset runs it inside one transaction, so it must stay fast.

alias ClothingStore.Repo
alias ClothingStore.Transactions.Transaction
alias ClothingStore.Products.ProductTransaction
alias ClothingStore.Products
alias ClothingStore.Users

# Photos: Pexels (pexels.com/license), plus CC0 photos from StockSnap and the WordPress
# photo directory (found through Openverse) for the knitwear, coats and the last few;
# resized and converted to WebP in priv/static/images/products/<slug>.webp.
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
   "A light grey zip-up track jacket with striped sleeves."},
  {"hoodie", "Fleece Hoodie", "Sportswear", "54.90", 22, ["popular", "winter"],
   "A soft grey-blue hoodie in brushed cotton fleece with a kangaroo pocket."},
  {"white-sneakers", "Canvas Sneakers", "Shoes", "49.90", 16, ["summer"],
   "Classic white canvas lace-up sneakers with a rubber toe cap."},
  {"maxi-dress", "Floral Maxi Dress", "Dresses & Skirts", "79.90", 7, ["summer", "new"],
   "A flowing ankle-length dress in a pale floral print with long sleeves."},
  {"knit-sweater", "Ribbed Knit Sweater", "Knitwear", "64.90", 11, ["winter"],
   "A cream sweater in a chunky rib knit, cosy and easy to layer."},
  {"cardigan", "Camel Cardigan", "Knitwear", "59.90", 2, ["new"],
   "A relaxed open-front cardigan in a camel wool blend."},
  {"denim-jacket", "Denim Jacket", "Jackets & Coats", "89.90", 13, ["popular"],
   "A light-wash denim trucker jacket with chest pockets."},
  {"leather-jacket", "Leather Biker Jacket", "Jackets & Coats", "229.00", 4, [],
   "A black leather biker jacket with an asymmetric zip and quilted shoulders."},
  {"puffer-jacket", "Hooded Puffer Jacket", "Jackets & Coats", "139.00", 8, ["winter"],
   "A lightweight quilted puffer in sage green with a hood and recycled filling."},
  {"trench-coat", "Classic Trench Coat", "Jackets & Coats", "179.00", 0, ["sale"],
   "A beige double-breasted trench coat with a belted waist."},
  {"tweed-coat", "Tweed Overcoat", "Jackets & Coats", "199.00", 5, ["winter", "new"],
   "A brown wool tweed overcoat with horn buttons, warm enough for real winters."}
]

# products tagged "sale" run a 20 % discount from a few days ago to a few days ahead
today = Date.utc_today()

# clothes come in S to XL, shoes in EU 39 to 43, accessories in one size; the stock is
# shared out with the middle sizes getting the most
sizes = fn
  "Shoes" -> {~w(39 40 41 42 43), [1, 2, 3, 2, 1]}
  "Accessories" -> {[], []}
  _clothes -> {~w(S M L XL), [1, 2, 2, 1]}
end

split = fn
  _stock, [] ->
    []

  stock, weights ->
    total = Enum.sum(weights)
    shares = Enum.map(weights, &div(stock * &1, total))
    # the rounding remainder goes to the biggest share
    {_, index} = shares |> Enum.with_index() |> Enum.max_by(&elem(&1, 0))
    List.update_at(shares, index, &(&1 + stock - Enum.sum(shares)))
end

for {slug, title, category, price, stock, tags, description} <- catalogue do
  discount =
    if "sale" in tags,
      do: %{
        discount_percent: 20,
        discount_starts_on: Date.add(today, -3),
        discount_ends_on: Date.add(today, 4)
      },
      else: %{}

  {names, weights} = sizes.(category)

  variants =
    for {size, size_stock} <- Enum.zip(names, split.(stock, weights)),
        do: %{size: size, stock: size_stock}

  {:ok, _} =
    Products.create_product(
      Map.merge(discount, %{
        variants: variants,
        title: title,
        description: description,
        category: category,
        photo: "/images/products/#{slug}.webp",
        price: Decimal.new(price),
        stock: stock,
        tags: tags
      })
    )
end

# the feed starts empty; the catalogue isn't news (the versions stay, for the price history)
Repo.delete_all(ClothingStore.ActivityFeed.Event)

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
      full_price: product.price,
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
