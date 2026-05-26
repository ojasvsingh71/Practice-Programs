from flask import Flask, render_template, request

app = Flask(__name__)

@app.route('/')
def home():
    return render_template('index.html')


@app.route('/attendance', methods=['POST'])
def attendance():
    student_name = request.form['student_name']
    total_classes = request.form['total_classes']
    attended_classes = request.form['attended_classes']

    # Validation
    if student_name == "" or total_classes == "" or attended_classes == "":
        return "Error: All fields are required!"

    try:
        total_classes = int(total_classes)
        attended_classes = int(attended_classes)
    except:
        return "Error: Classes must be numeric!"

    if total_classes <= 0:
        return "Error: Total classes must be greater than 0!"

    if attended_classes > total_classes:
        return "Error: Attended classes cannot exceed total classes!"

    # Attendance Calculation
    attendance_percentage = (attended_classes / total_classes) * 100

    # Eligibility Check
    if attendance_percentage >= 75:
        eligibility = "Eligible for Exams"
    else:
        eligibility = "Not Eligible for Exams"

    return render_template(
        'index.html',
        success=True,
        student_name=student_name,
        total_classes=total_classes,
        attended_classes=attended_classes,
        attendance_percentage=round(attendance_percentage, 2),
        eligibility=eligibility
    )


if __name__ == '__main__':
    app.run(debug=True)