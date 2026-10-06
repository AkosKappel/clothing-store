# Clothing Store

Author: **Ákos Kappel**

Live Demo: **[Modern Fashion Store](https://tagline.tailb52c43.ts.net)** (press **Try the demo** on the login page; the data resets every night)

# Table of Contents

- [Tech stack](#tech-stack)
- [Running the app](#running-the-app)
  - [Locally](#locally)
  - [With Docker](#with-docker)
- [Screenshots](#screenshots)
  - [Login Page](#login-page)
  - [Home](#home)
  - [Product Detail](#product-detail)
  - [Product Form](#product-form)
  - [Inventory with Filters](#inventory-with-filters)
  - [Transactions with Month Filter](#transactions-with-month-filter)
  - [Bestsellers](#bestsellers)
- [Task 1](#task-1-required)
- [Task 2](#task-2-required)
- [Task 3](#task-3-optional)
- [Task 4](#task-4-optional)
- [Task 5](#task-5-optional)
- [Task 6](#task-6-optional)
- [Bonus](#bonus)


## Tech stack

- Elixir 1.20 / OTP 29, Phoenix 1.8, Phoenix LiveView 1.2
- Tailwind CSS 4 and esbuild, Bandit web server
- PostgreSQL 18
- nginx 1.30 in front of the app in production
- Built as a `mix release` in a multi-stage Docker image

## Running the app

### Locally

1. Install Erlang and Elixir with [mise](https://mise.jdx.dev): `mise install` (versions are pinned in `mise.toml`).
2. Create the configuration: `cp .env.example .env`, fill in `DB_PASSWORD` (and the other database values if you changed them), then `chmod 600 .env`. Locally only the database settings are read from `.env`; `SECRET_KEY_BASE` is not needed. The seeded demo account uses the defaults `admin@eshop.com` / `Qwerty123456` (used by **Try the demo**) unless you export `ADMIN_EMAIL` / `ADMIN_PASSWORD` in your shell.
3. Start PostgreSQL: `docker compose up -d db` (listens on `127.0.0.1:5435` and creates the `tagline`, `tagline_dev` and `tagline_test` databases).
4. Run `mix setup` to install dependencies, create and migrate the database and seed it.
5. Start the server with `mix phx.server` (or `iex -S mix phx.server`) and visit [`localhost:4000`](http://localhost:4000).

Run `mix precommit` before committing: it compiles with warnings as errors, removes unused entries from `mix.lock`, formats the code (rewriting files) and runs the tests.

### With Docker

1. Create `.env` as in step 2 above (`cp .env.example .env`, `chmod 600 .env`) and fill in `DB_PASSWORD` and `ADMIN_PASSWORD`. Also set `SECRET_KEY_BASE` to a random secret, for example the output of `openssl rand -base64 48`; compose refuses to start without all three.
2. Build and start everything:

```
docker compose up -d --build
```

The app is then available at [`127.0.0.1:8083`](http://127.0.0.1:8083) (nginx in front of the app). On first start the app migrates the database and seeds it if it is empty.

## Screenshots

### Login Page

![Login page](screenshots/LoginPage.png)

### Home

![Home page](screenshots/HomePage.png)

### Product Detail

![Product detail page](screenshots/ProductDetailPage.png)

### Product Form

![Product form page](screenshots/ProductForm.png)

### Inventory with Filters

![Inventory page](screenshots/InventoryPage.png)

### Transactions with Month Filter

![Transactions page](screenshots/TransactionsPage.png)

### Bestsellers

![Statistics page](screenshots/StatisticsPage.png)

## Task 1 (required)

Create a simple dashboard interface for a manager of a clothing company. This dashboard should display all products that are available for sale, manager should be able to add, edit and delete the items.

Specifications:

- Use Phoenix framework and Tailwind (Flowbite)
- Use PostgresDB
- Generate seeds for at least 10 products
- Each product should have at least these mandatory fields:
  - Photo
  - Title
  - Description
  - Category
  - Price
  - Stock
- User must be able to:
  - add / edit / delete a product
- Implement a filter over the products

### Solution

I installed Elixir with Phoenix framework and setup PostgreSQL.
In the [`priv/repo/seeds.exs`](priv/repo/seeds.exs) I generated 10 products whose images I took randomly from the internet and the prices are made up.
The structure of the products is defined in the migration file (it has all the required fields).
CRUD operations are defined in the [`lib/clothing_store_web/controllers/product_controller.ex`](lib/clothing_store_web/controllers/product_controller.ex) file and the corresponding SQL ORM queries are defined in the [`lib/clothing_store/products.ex`](lib/clothing_store/products.ex) file.
The admin has the option to view, add, edit and delete the products.
For the user interface I used Tailwind to customize the design, and I made sure to make most of the components responsive.
Finally, I implemented the filter over the products.
The user has the option to filter by category, minimum or maximum price, and by availability of the product.

## Task 2 (required)

Create dashboard with statistics/inventory/transactions over the products.

Specifications:

- Use Phoenix framework and Tailwind (Flowbite)
- Use PostgresDB
  - Generate seeds for at least 10 transactions
- Dashboard should visualize:
  - How many products are in stock
  - Best selling product
  - Number of transactions for the whole month (with filter for months)

### Solution

This task is continuing in the development of the first task.
First, I created 3 pages for the dashboard: `Inventory`, `Transactions` and `Statistics`.
The `Inventory` page shows the list of products from the first task (stock count is shown in a column for each product).
On the `Transactions` page, the user can see all the transactions.
A transaction can have multiple products.
This is achieved by a many-to-many relationship between the `transactions` and `products` tables.
The migration files define these relationships and create a pivoted table `products_transactions`.
Then, I modified the seeder to generate 10 random transactions.
The `Transactions` page also allows the user to filter the transactions by month.
There is a datepicker to select a specific month in a calendar, and a filter button to apply this filter.
Finally, the `Statistics` page shows the top 3 best selling products of all time, the current and the previous month.
Bestsellers are calculated by summing the number of times a product has been sold.

## Task 3 (optional)

User login screen

### Solution

For the login functionality I used the `mix phx.gen.auth` library.
This auto-generated all the necessary files for the user authentication, as well as the registration and login forms.
The library also provides a settings page for the user to change their email or password.
I customized the generated forms and disabled registration for new users, because the seeder automatically creates the admin, and new users are not allowed to register.
For demonstration purposes, the login form is automatically filled with the admin credentials, because all the dashboard routes are protected.

## Task 4 (optional)

LiveFeed for multiple users - Using the PubSub module

### Solution

To implement this, I used the `Phoenix.PubSub` module.
I created a channel called `products` in the [`lib/clothing_store_web/live/product_live/index.ex`](lib/clothing_store_web/live/product_live/index.ex) file.
The channel is used to broadcast events, such as when a product is added, modified, or deleted.
When an event is broadcasted, all the connected clients are notified, and their homepage with the products is updated accordingly, without having to reload the page.

## Task 5 (optional)

Using tags as categories (multiple tags per item)

### Solution

To implement this, I needed to create a new migration, that modifies the `products` table, and adds a new field called `tags`, which is a JSON array of strings.
Following this, I accordingly modified the products seeder and updated the dashboard interface as well as the CRUD operations, to work with the new field.

## Task 6 (optional)

Implementation of the filter over multiple tags

### Solution

For this task, I used the new `tags` field that I added in the previous task.
I added checkboxes for each tag in the filter form, and the user can now select any number of tags.
The results are then filtered, so that only products that contain at least one of the selected tags are shown.
Also, any of the filters can be combined together, for example, you can select a tag and a min price filter, and the products will be filtered by these conditions.

## Bonus

The app runs as a Docker release on a home server, behind nginx (security headers and rate limiting) and is published to the internet with a Tailscale Funnel sidecar container, at [tagline.tailb52c43.ts.net](https://tagline.tailb52c43.ts.net).
It is a public demo: **Try the demo** logs you in as the shared demo account (server-side, its password never reaches the browser), the data resets every night (by default at 03:00 Europe/Bratislava time, configurable with the `DEMO_RESET_*` settings), the e-mail and password of the demo account can't be changed, registration is disabled, and e-mails are only logged, never sent.
The seed photos are Pexels photos served locally as WebP.
In 2026 I upgraded the app from Phoenix 1.7, LiveView 1.0 and Tailwind 3 to the current versions listed in the [tech stack](#tech-stack).
