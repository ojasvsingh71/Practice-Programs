from flask import Flask, render_template, request

app = Flask(__name__)

@app.route('/')
def home():
    return render_template('index.html')


@app.route('/grade', methods=['POST'])
def grade():
    student_name = request.form['student_name']
    internal_marks = request.form['internal_marks']
    external_marks = request.form['external_marks']

    # Validation
    if student_name == "" or internal_marks == "" or external_marks == "":
        return "Error: All fields are required!"

    try:
        internal_marks = float(internal_marks)
        external_marks = float(external_marks)
    except:
        return "Error: Marks must be numeric!"

    # Total Marks
    total_marks = internal_marks + external_marks

    # Grade Calculation
    if total_marks >= 90:
        grade = "A+"
    elif total_marks >= 75:
        grade = "A"
    elif total_marks >= 60:
        grade = "B"
    elif total_marks >= 40:
        grade = "C"
    else:
        grade = "Fail"

    return render_template(
        'index.html',
        success=True,
        student_name=student_name,
        internal_marks=internal_marks,
        external_marks=external_marks,
        total_marks=total_marks,
        grade=grade
    )


if __name__ == '__main__':
    app.run(debug=True)