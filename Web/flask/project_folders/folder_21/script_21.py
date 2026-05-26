from flask import Flask, render_template, request

app = Flask(__name__)

FINE_PER_DAY = 5  # ₹5 fine per late day

@app.route('/')
def home():
    return render_template('index.html')


@app.route('/fine', methods=['POST'])
def fine():
    student_name = request.form['student_name']
    book_name = request.form['book_name']
    days_late = request.form['days_late']

    # Validation
    if student_name == "" or book_name == "" or days_late == "":
        return "Error: All fields are required!"

    try:
        days_late = int(days_late)
    except:
        return "Error: Days Late must be numeric!"

    if days_late < 0:
        return "Error: Days Late cannot be negative!"

    # Fine Calculation
    fine_amount = days_late * FINE_PER_DAY

    return render_template(
        'index.html',
        success=True,
        student_name=student_name,
        book_name=book_name,
        days_late=days_late,
        fine_amount=fine_amount
    )


if __name__ == '__main__':
    app.run(debug=True)