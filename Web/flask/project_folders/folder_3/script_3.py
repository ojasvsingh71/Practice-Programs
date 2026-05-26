from flask import Flask, render_template, request

app = Flask(__name__)

@app.route('/')
def home():
    return render_template('index.html')


@app.route('/bmi', methods=['POST'])
def bmi():
    username = request.form['username']
    password = request.form['password']
    weight = request.form['weight']
    height = request.form['height']

    # Validation
    if username == "" or password == "" or weight == "" or height == "":
        return "Error: All fields are required!"

    if len(password) < 6:
        return "Error: Password must contain at least 6 characters!"

    try:
        weight = float(weight)
        height = float(height)
    except:
        return "Error: Weight and Height must be numeric!"

    if weight <= 0 or height <= 0:
        return "Error: Weight and Height must be positive!"

    # BMI Calculation
    bmi_value = weight / (height * height)

    # Health Category
    if bmi_value < 18.5:
        category = "Underweight"
    elif bmi_value < 25:
        category = "Normal Weight"
    elif bmi_value < 30:
        category = "Overweight"
    else:
        category = "Obese"

    return render_template(
        'index.html',
        success=True,
        username=username,
        weight=weight,
        height=height,
        bmi=round(bmi_value, 2),
        category=category
    )


if __name__ == '__main__':
    app.run(debug=True)