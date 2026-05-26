from flask import Flask, render_template, request

app = Flask(__name__)

@app.route('/')
def home():
    return render_template('index.html')


@app.route('/salary', methods=['POST'])
def salary():
    employee_name = request.form['employee_name']
    working_days = request.form['working_days']
    days_present = request.form['days_present']
    salary_per_day = request.form['salary_per_day']

    # Validation
    if employee_name == "" or working_days == "" or days_present == "" or salary_per_day == "":
        return "Error: All fields are required!"

    try:
        working_days = int(working_days)
        days_present = int(days_present)
        salary_per_day = float(salary_per_day)
    except:
        return "Error: Working Days, Days Present, and Salary must be numeric!"

    if days_present > working_days:
        return "Error: Days Present cannot exceed Working Days!"

    # Salary Calculation
    monthly_salary = days_present * salary_per_day

    # Attendance Percentage
    attendance_percentage = (days_present / working_days) * 100

    return render_template(
        'index.html',
        success=True,
        employee_name=employee_name,
        working_days=working_days,
        days_present=days_present,
        salary_per_day=salary_per_day,
        monthly_salary=round(monthly_salary, 2),
        attendance_percentage=round(attendance_percentage, 2)
    )


if __name__ == '__main__':
    app.run(debug=True)