# Script for populating the database. You can run it as: `mix run priv/repo/seeds.exs`

alias ClothingStore.Repo
alias ClothingStore.Transactions.Transaction
alias ClothingStore.Products.ProductTransaction
alias ClothingStore.Products
alias ClothingStore.Users

products = [
  %{
    title: "T-Shirt",
    description: """
    A T-Shirt is a type of casual shirt that is generally short-sleeved and collarless.
    It is a popular casual wear item that is often worn for recreational activities.
    """,
    category: "Shirt",
    photo: "https://images.pexels.com/photos/325876/pexels-photo-325876.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
    price: Decimal.new("19.99"),
    stock: 10,
    tags: ["new", "popular", "sale"],
  },
  %{
    title: "Jeans",
    description: "A pair of Jeans",
    category: "Clothing",
    photo: "https://images.pexels.com/photos/45982/pexels-photo-45982.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
    price: Decimal.new("1049.99"),
    stock: 5,
    tags: ["new"],
  },
  %{
    title: "Sweater",
    description: """
    This is a sweater. It is a piece of clothing that is typically made of thick, warm fabric such as wool, and is often worn over a shirt or other top for warmth. It can be long or short, and can be worn for casual or dressy occasions. This sweater is a great choice for anyone looking for a cozy and comfortable piece of clothing.
    """,
    category: "Clothing",
    photo: "https://images.pexels.com/photos/297933/pexels-photo-297933.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
    price: Decimal.new("29.99"),
    stock: 0,
    tags: ["popular"],
  },
  %{
    title: "Shoes",
    description: "A very nice pair of shoes with a unique design",
    category: "Footwear",
    photo: "https://images.pexels.com/photos/2081332/pexels-photo-2081332.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
    price: Decimal.new("159.99"),
    stock: 2,
    tags: ["sale"],
  },
  %{
    title: "Jacket",
    description: "A jacket for the cold weather",
    category: "Clothing",
    photo: "https://images.pexels.com/photos/2249249/pexels-photo-2249249.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
    price: Decimal.new("5.99"),
    stock: 7,
    tags: ["new", "sale"],
  },
  %{
    title: "Boots",
    description: "New boots",
    category: "Footwear",
    photo: "https://images.pexels.com/photos/3315286/pexels-photo-3315286.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
    price: Decimal.new("50.59"),
    stock: 20,
    tags: [],
  },
  %{
    title: "Sneakers",
    description: "A pair of white sneakers for the street",
    category: "Footwear",
    photo: "https://images.pexels.com/photos/3353621/pexels-photo-3353621.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
    price: Decimal.new("529.99"),
    stock: 0,
    tags: ["eco-friendly", "new"],
  },
  %{
    title: "Pants",
    description: """
    These are casual pants for everyday use. They are perfect for lounging around the house, running errands, or going out with friends. They are made of a comfortable material and have a relaxed fit.
    """,
    category: "Clothing",
    photo: "https://images.pexels.com/photos/4066290/pexels-photo-4066290.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
    price: Decimal.new("9.99"),
    stock: 61,
    tags: ["eco-friendly"],
  },
  %{
    title: "Dress",
    description: "Stylish dress for a special occasion",
    category: "Clothing",
    photo: "https://images.pexels.com/photos/4352249/pexels-photo-4352249.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
    price: Decimal.new("100.00"),
    stock: 9,
    tags: ["modern"],
  },
  %{
    title: "Sunglasses",
    description: "A pair of black sunglasses",
    category: "Accessories",
    photo: "https://images.pexels.com/photos/1578997/pexels-photo-1578997.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
    price: Decimal.new("4.99"),
    stock: 4,
    tags: ["popular", "modern", "sale"],
  },
]

# Insert the products into the database
for product <- products do
  Products.create_product(product)
end

# Fetch newly created products
products = Products.list_products()

create_product_transactions_and_total = fn products, transaction_id ->
  product_transactions =
    Enum.take_random(products, Enum.random(1..5)) # Select randomly N products
    |> Enum.map(fn product ->
      quantity = Enum.random(1..3) # Take a random quantity
      %ProductTransaction{
        product_id: product.id,
        transaction_id: transaction_id,
        quantity: quantity
      }
    end)

  total_price =
    # Calculate the total price of the transaction items
    Enum.reduce(product_transactions, Decimal.new(0), fn pt, acc ->
      product = Enum.find(products, &(&1.id == pt.product_id))
      Decimal.add(acc, Decimal.mult(product.price, Decimal.new(pt.quantity)))
    end)

  {product_transactions, total_price}
end

generate_random_date = fn ->
  # Generate a random number of days between 0 and 90
  random_days = :rand.uniform(90)

  # Get the current UTC time
  now = DateTime.utc_now()

  # Subtract the random number of days from the current time
  DateTime.add(now, -random_days * 86400, :second)
  |> DateTime.truncate(:second)  # Ensure we remove any microseconds
end

for _ <- 1..10 do
  # Create a new transaction with a total price of 0 (which will be updated later)
  transaction =
    %Transaction{
      total_price: Decimal.new(0),
      inserted_at: generate_random_date.(),
      updated_at: DateTime.utc_now() |> DateTime.truncate(:second)
    }
    |> Repo.insert!()

  # Create a number of product transactions with random quantities and calculate the total price
  {product_transactions, total_price} = create_product_transactions_and_total.(products, transaction.id)

  # Insert each product transaction into the database
  for product_transaction <- product_transactions do
    Repo.insert!(product_transaction)
  end

  # Update the transaction with the calculated total price
  transaction
  |> Ecto.Changeset.change(total_price: total_price)
  |> Repo.update!()
end

# Generate admin user
Users.register_user(%{email: "admin@eshop.com", password: "Qwerty123456", role: "admin"})
