from flask import Flask, render_template, request

app = Flask(__name__)

@app.route('/')
def home():
    return render_template('index.html')


@app.route('/register', methods=['POST'])
def register():
    student_name = request.form['student_name']
    course_name = request.form['course_name']
    course_fee = request.form['course_fee']
    discount_percentage = request.form['discount_percentage']

    # Validation
    if student_name == "" or course_name == "" or course_fee == "" or discount_percentage == "":
        return "Error: All fields are required!"

    try:
        course_fee = float(course_fee)
        discount_percentage = float(discount_percentage)
    except:
        return "Error: Course Fee and Discount Percentage must be numeric!"

    # Discount Calculation
    discount_amount = (course_fee * discount_percentage) / 100
    discounted_fee = course_fee - discount_amount

    return render_template(
        'index.html',
        success=True,
        student_name=student_name,
        course_name=course_name,
        course_fee=course_fee,
        discount_percentage=discount_percentage,
        discount_amount=round(discount_amount, 2),
        discounted_fee=round(discounted_fee, 2)
    )


if __name__ == '__main__':
    app.run(debug=True)