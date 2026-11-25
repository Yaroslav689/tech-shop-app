import psycopg2
import psycopg2.extras
from flask import Flask, render_template, request, redirect, url_for

app = Flask(__name__)

DB = dict(host="localhost", port=5432, dbname="tech_shop", user="postgres", password="пароль")

def db(sql, params=(), fetch="all"):
    conn = psycopg2.connect(**DB)
    try:
        with conn, conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(sql, params)
            if fetch == "all":
                return cur.fetchall()
            if fetch == "one":
                return cur.fetchone()
    finally:
        conn.close()

@app.route("/")
def products_list():
    products = db("""SELECT p.*, c.name AS category
                     FROM products p JOIN categories c ON c.id = p.category_id
                     ORDER BY p.name""")
    return render_template("list.html", products=products)

@app.route("/product/<int:id>")
def product_detail(id):
    product = db("""SELECT p.*, c.name AS category
                    FROM products p JOIN categories c ON c.id = p.category_id
                    WHERE p.id = %s""", (id,), fetch="one")
    history = db("""SELECT * FROM price_history
                    WHERE product_id = %s
                    ORDER BY changed_at DESC, id DESC""", (id,))
    return render_template("detail.html", product=product, history=history)

@app.route("/product/new", methods=["GET", "POST"])
def product_create():
    if request.method == "POST":
        f = request.form
        db("INSERT INTO products (name, price, stock, category_id) VALUES (%s,%s,%s,%s)",
           (f["name"], f["price"], f["stock"], f["category_id"]), fetch=None)
        return redirect(url_for("products_list"))

    categories = db("SELECT * FROM categories ORDER BY name")
    return render_template("form.html", product={}, categories=categories)

@app.route("/product/<int:id>/edit", methods=["GET", "POST"])
def product_edit(id):
    if request.method == "POST":
        f = request.form
        db("""UPDATE products
              SET name=%s, stock=%s, category_id=%s
              WHERE id=%s""",
           (f["name"], f["stock"], f["category_id"], id),
           fetch=None)
        db("SELECT update_product_price(%s, %s)",
           (id, f["price"]), fetch=None)
        return redirect(url_for("product_detail", id=id))

    product = db("SELECT * FROM products WHERE id = %s",(id,), fetch="one")
    categories = db("SELECT * FROM categories ORDER BY name")
    return render_template("form.html", product=product, categories=categories)

@app.route("/product/<int:id>/delete", methods=["POST"])
def product_delete(id):
    db("DELETE FROM products WHERE id = %s", (id,), fetch=None)
    return redirect(url_for("products_list"))

if __name__ == "__main__":
    app.run(debug=True)