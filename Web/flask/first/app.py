from flask import Flask
from flask import jsonify
from flask import render_template
from flask import request

app=Flask(__name__)

@app.route('/')
def home():
    return "Hello Ojasv!"

@app.route('/about')
def about():
    return jsonify({
        "Name":"Ojasv"
    })

@app.route('/form',methods=["POST","GET"])
def form():
    if request.method =="POST":
        name=request.form["username"]
        return f"Hi {name}"
    return render_template("form.html")

@app.route('/test')
def test():
    return render_template("index.html",name="Khushi")

if __name__ == '__main__':
    app.run(debug=True)