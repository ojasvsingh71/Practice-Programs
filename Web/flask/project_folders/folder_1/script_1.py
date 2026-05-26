from flask import Flask, render_template, request

app = Flask(__name__)

@app.route('/')
def home():
    return render_template('index.html')


@app.route('/result', methods=['POST'])
def result():
    email = request.form['email']
    password = request.form['password']

    marks = [
        int(request.form['mark1']),
        int(request.form['mark2']),
        int(request.form['mark3']),
        int(request.form['mark4']),
        int(request.form['mark5'])
    ]

    # Validation
    if email == "" or password == "":
        return "Error: No field should be empty!"

    if len(password) < 6:
        return "Error: Password must contain at least 6 characters!"

    for mark in marks:
        if mark < 0 or mark > 100:
            return "Error: Marks must be between 0 and 100!"

    # Login Check
    if email == "student@school.com" and password == "stud123":

        total = sum(marks)
        percentage = total / 5

        # Grade Calculation
        if percentage >= 90:
            grade = "A+"
        elif percentage >= 75:
            grade = "A"
        elif percentage >= 60:
            grade = "B"
        elif percentage >= 40:
            grade = "C"
        else:
            grade = "Fail"

        return render_template(
            'index.html',
            success=True,
            email=email,
            marks=marks,
            total=total,
            percentage=percentage,
            grade=grade
        )

    else:
        return render_template(
            'index.html',
            error="Invalid Email ID or Password!"
        )


if __name__ == '__main__':
    app.run(debug=True)