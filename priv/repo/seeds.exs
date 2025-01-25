# Script for populating the database. You can run it as: `mix run priv/repo/seeds.exs`

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
  },
  %{
    title: "Jeans",
    description: "A pair of Jeans",
    category: "Clothing",
    photo: "https://images.pexels.com/photos/45982/pexels-photo-45982.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
    price: Decimal.new("1049.99"),
    stock: 5,
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
  },
  %{
    title: "Shoes",
    description: "A very nice pair of shoes with a unique design",
    category: "Footwear",
    photo: "https://images.pexels.com/photos/2081332/pexels-photo-2081332.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
    price: Decimal.new("159.99"),
    stock: 2,
  },
  %{
    title: "Jacket",
    description: "A jacket for the cold weather",
    category: "Clothing",
    photo: "https://images.pexels.com/photos/2249249/pexels-photo-2249249.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
    price: Decimal.new("5.99"),
    stock: 7,
  },
  %{
    title: "Boots",
    description: "New boots",
    category: "Footwear",
    photo: "https://images.pexels.com/photos/3315286/pexels-photo-3315286.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
    price: Decimal.new("50.59"),
    stock: 20,
  },
  %{
    title: "Sneakers",
    description: "A pair of white sneakers for the street",
    category: "Footwear",
    photo: "https://images.pexels.com/photos/3353621/pexels-photo-3353621.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
    price: Decimal.new("529.99"),
    stock: 0,
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
  },
  %{
    title: "Dress",
    description: "Stylish dress for a special occasion",
    category: "Clothing",
    photo: "https://images.pexels.com/photos/4352249/pexels-photo-4352249.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
    price: Decimal.new("100"),
    stock: 9,
  },
  %{
    title: "Sunglasses",
    description: "A pair of black sunglasses",
    category: "Accessories",
    photo: "https://images.pexels.com/photos/1578997/pexels-photo-1578997.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
    price: Decimal.new("4.99"),
    stock: 4,
  },
]

for product <- products do
  ClothingStore.Products.create_product(product)
end
