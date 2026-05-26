from flask import Flask, render_template, request

app = Flask(__name__)

@app.route('/')
def home():
    return render_template('index.html')


@app.route('/book', methods=['POST'])
def book():
    user_name = request.form['user_name']
    movie_name = request.form['movie_name']
    tickets = request.form['tickets']
    ticket_price = request.form['ticket_price']

    # Validation
    if user_name == "" or movie_name == "" or tickets == "" or ticket_price == "":
        return "Error: All fields are required!"

    try:
        tickets = int(tickets)
        ticket_price = float(ticket_price)
    except:
        return "Error: Tickets and Ticket Price must be numeric!"

    # Bill Calculation
    total_bill = tickets * ticket_price

    return render_template(
        'index.html',
        success=True,
        user_name=user_name,
        movie_name=movie_name,
        tickets=tickets,
        ticket_price=ticket_price,
        total_bill=total_bill
    )


if __name__ == '__main__':
    app.run(debug=True)