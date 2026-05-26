from flask import Flask, render_template, request

app = Flask(__name__)

@app.route('/')
def home():
    return render_template('index.html')


@app.route('/salary', methods=['POST'])
def salary():
    emp_id = request.form['emp_id']
    emp_name = request.form['emp_name']
    basic_salary = request.form['basic_salary']
    bonus_percent = request.form['bonus_percent']

    # Validation
    if emp_id == "" or emp_name == "" or basic_salary == "" or bonus_percent == "":
        return "Error: All fields are required!"

    try:
        basic_salary = float(basic_salary)
        bonus_percent = float(bonus_percent)
    except:
        return "Error: Salary and Bonus must be numeric!"

    # Salary Calculations
    hra = basic_salary * 0.20
    da = basic_salary * 0.10
    bonus = basic_salary * (bonus_percent / 100)

    net_salary = basic_salary + hra + da + bonus

    return render_template(
        'index.html',
        success=True,
        emp_id=emp_id,
        emp_name=emp_name,
        basic_salary=basic_salary,
        hra=hra,
        da=da,
        bonus=bonus,
        net_salary=net_salary
    )


if __name__ == '__main__':
    app.run(debug=True)