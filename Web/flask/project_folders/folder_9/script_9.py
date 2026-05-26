from flask import Flask, render_template, request

app = Flask(__name__)

@app.route('/')
def home():
    return render_template('index.html')


@app.route('/book', methods=['POST'])
def book():
    guest_name = request.form['guest_name']
    room_type = request.form['room_type']
    days = request.form['days']
    price_per_day = request.form['price_per_day']

    # Validation
    if guest_name == "" or room_type == "" or days == "" or price_per_day == "":
        return "Error: All fields are required!"

    try:
        days = int(days)
        price_per_day = float(price_per_day)
    except:
        return "Error: Number of Days and Price per Day must be numeric!"

    # Room Rent Calculation
    total_rent = days * price_per_day

    return render_template(
        'index.html',
        success=True,
        guest_name=guest_name,
        room_type=room_type,
        days=days,
        price_per_day=price_per_day,
        total_rent=total_rent
    )


if __name__ == '__main__':
    app.run(debug=True)