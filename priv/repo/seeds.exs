# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     ClothingStore.Repo.insert!(%ClothingStore.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

products = [
  %{
    title: "T-Shirt",
    description: """
    A T-Shirt is a type of casual shirt that is generally short-sleeved and collarless.
    It is a popular casual wear item that is often worn for recreational activities.
    """,
    category: "Clothing",
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
    stock: 1,
  },
  %{
    title: "Shoes",
    description: "A pair of shoes",
    category: "Clothing",
    photo: "https://images.pexels.com/photos/2081332/pexels-photo-2081332.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
    price: Decimal.new("159.99"),
    stock: 2,
  },
  %{
    title: "Jacket",
    description: "A jacket",
    category: "Clothing",
    photo: "https://images.pexels.com/photos/2249249/pexels-photo-2249249.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
    price: Decimal.new("5.99"),
    stock: 7,
  },
]

for product <- products do
  ClothingStore.Products.create_product(product)
end
