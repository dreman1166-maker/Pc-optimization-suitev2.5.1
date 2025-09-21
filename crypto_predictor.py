import requests
import time
import datetime
import matplotlib.pyplot as plt
import matplotlib.animation as animation
import logging
import subprocess
import sys

# Supported symbols for Binance and CoinGecko
SYMBOLS = {
    'BTCUSDT': {'binance': 'BTCUSDT', 'coingecko': ('bitcoin', 'usd')},
    'ETHUSDT': {'binance': 'ETHUSDT', 'coingecko': ('ethereum', 'usd')},
    'LTCUSDT': {'binance': 'LTCUSDT', 'coingecko': ('litecoin', 'usd')},
    'BNBUSDT': {'binance': 'BNBUSDT', 'coingecko': ('binancecoin', 'usd')},
    'XRPUSDT': {'binance': 'XRPUSDT', 'coingecko': ('ripple', 'usd')},
    'EURUSDT': {'binance': 'EURUSDT', 'coingecko': ('eur', 'usd')},
    'USDUSDT': {'binance': 'USDUSDT', 'coingecko': ('usd', 'usd')},
    'DOGEUSDT': {'binance': 'DOGEUSDT', 'coingecko': ('dogecoin', 'usd')},
    'ADAUSDT': {'binance': 'ADAUSDT', 'coingecko': ('cardano', 'usd')},
    'SOLUSDT': {'binance': 'SOLUSDT', 'coingecko': ('solana', 'usd')},
}

def select_symbol():
    print("Select a symbol to track:")
    for i, sym in enumerate(SYMBOLS.keys()):
        print(f"{i+1}. {sym}")
    idx = int(input("Enter number: ")) - 1
    return list(SYMBOLS.keys())[idx]

def get_binance_price(symbol):
    url = f"https://api.binance.com/api/v3/ticker/price?symbol={symbol}"
    response = requests.get(url)
    data = response.json()
    if 'price' not in data:
        print(f"Binance API response error: {data}")
        raise Exception("'price' not found in Binance API response")
    return float(data['price'])

def get_coingecko_price(coin_id, vs_currency):
    url = f"https://api.coingecko.com/api/v3/simple/price?ids={coin_id}&vs_currencies={vs_currency}"
    response = requests.get(url)
    data = response.json()
    if coin_id not in data or vs_currency not in data[coin_id]:
        print(f"CoinGecko API response error: {data}")
        raise Exception(f"'{vs_currency}' not found in CoinGecko API response for {coin_id}")
    return float(data[coin_id][vs_currency])

def moving_average(prices, window=5):
    if len(prices) < window:
        return sum(prices) / len(prices)
    return sum(prices[-window:]) / window

# Setup logging
logging.basicConfig(
    filename='crypto_predictor.log',
    level=logging.INFO,
    format='%(asctime)s | %(levelname)s | %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)

symbol = select_symbol()
binance_symbol = SYMBOLS[symbol]['binance']
coingecko_id, coingecko_vs = SYMBOLS[symbol]['coingecko']
logging.info('--- Script started for symbol: %s ---', symbol)

# Ask user for investment amount
while True:
    try:
        investment = float(input("Enter your investment amount in USD: "))
        if investment > 0:
            break
        else:
            print("Please enter a positive number.")
    except ValueError:
        print("Invalid input. Please enter a number.")

# Initialize global variables
prices = []
timestamps = []
predictions = []
buy_in_points = []
prediction_results = []
buy_in_price = None
buy_in_announced = False
window = 5  # Set window variable

# Pocket Options simulation mode
POCKET_OPTIONS_MODE = True  # Set to True to enable simulation
po_trades = []  # List of (buy_time, buy_price, sell_time, sell_price, result)
po_trade_open = None  # (buy_time, buy_price)
po_trade_duration = 60  # seconds (1 min trade)
po_profit_pct = 0.8  # 80% payout for win

# Create plot
fig, ax = plt.subplots()
plt.ion()

def get_latest_signal():
    """
    Returns a string with the latest prediction and price for Discord bot usage.
    """
    if not prices or not predictions:
        return "No signal yet."
    last_price = prices[-1]
    last_pred = predictions[-1]
    conf = 0.0
    if len(prices) > 2:
        if last_pred == 'UP':
            conf = (prices[-1] - prices[-2]) / (prices[-2] - prices[-3]) * 100 if (prices[-2] - prices[-3]) != 0 else 0.0
        elif last_pred == 'DOWN':
            conf = (prices[-3] - prices[-2]) / (prices[-2] - prices[-1]) * 100 if (prices[-2] - prices[-1]) != 0 else 0.0
    return f"{symbol}: {last_pred} | Price: {last_price:.2f} | Confidence: {conf:.1f}%"

def run_predictor():
    global buy_in_price, notice_given
    # Main loop
    while True:
        try:
            # --- Data Collection ---
            price_binance = get_binance_price(binance_symbol)
            price_coingecko = get_coingecko_price(coingecko_id, coingecko_vs)
            now = datetime.datetime.now()

            # Print and log prices
            price_log = f"{now.strftime('%Y-%m-%d %H:%M:%S')} | Binance: {price_binance:.2f} | CoinGecko: {price_coingecko:.2f}"
            print(price_log)
            logging.info(price_log)

            # Append data for analysis
            prices.append(price_binance)
            timestamps.append(now)

            # --- Prediction Logic ---
            # Simple prediction: UP if price increased, DOWN if decreased, FLAT if no change
            if len(prices) > 1:
                if prices[-1] > prices[-2]:
                    prediction = 'UP'
                elif prices[-1] < prices[-2]:
                    prediction = 'DOWN'
                else:
                    prediction = 'FLAT'
            else:
                prediction = 'FLAT'
            predictions.append(prediction)

            # Calculate confidence as the percentage of price movement in the predicted direction
            if len(prices) > 2:
                if prediction == 'UP':
                    confidence = (prices[-1] - prices[-2]) / (prices[-2] - prices[-3]) * 100
                elif prediction == 'DOWN':
                    confidence = (prices[-3] - prices[-2]) / (prices[-2] - prices[-1]) * 100
                else:
                    confidence = 0.0
            else:
                confidence = 0.0

            # --- Perfect Execution Buy-in Logic ---
            # Buy-in if the last prediction was DOWN or FLAT and now it's UP (trend reversal)
            if len(predictions) > 1:
                if (predictions[-2] in ['DOWN', 'FLAT']) and (predictions[-1] == 'UP'):
                    if not buy_in_announced:
                        buyin_msg = f"*** PERFECT EXECUTION: BUY-IN SIGNAL at {now.strftime('%Y-%m-%d %H:%M:%S')} | Price: {price_binance:.2f} ***"
                        print(f"\n{buyin_msg}\n")
                        logging.info(buyin_msg)
                        buy_in_points.append((now, price_binance))
                        buy_in_announced = True
                        buy_in_price = price_binance  # Set buy-in price
                elif predictions[-1] != 'UP':
                    buy_in_announced = False  # Reset for next opportunity

            # Calculate and display profit/loss if buy-in has occurred
            if buy_in_price:
                coins_bought = investment / buy_in_price
                current_value = coins_bought * price_binance
                profit = current_value - investment
                profit_msg = f"If you invested ${investment:.2f} at buy-in price {buy_in_price:.2f}, your current value is ${current_value:.2f} (Profit: ${profit:+.2f})"
                print(profit_msg)
                logging.info(profit_msg)

            # 2-3 min future trend (simple): compare current MA to MA 2-3 min ago
            three_min_ago = now - datetime.timedelta(minutes=3)
            two_min_ago = now - datetime.timedelta(minutes=2)
            ma_3min_ago = None
            ma_2min_ago = None
            for i, t in enumerate(timestamps):
                if ma_3min_ago is None and t >= three_min_ago:
                    ma_3min_ago = moving_average(prices[:i+1], window)
                if ma_2min_ago is None and t >= two_min_ago:
                    ma_2min_ago = moving_average(prices[:i+1], window)
            if ma_3min_ago and ma_2min_ago:
                if ma_2min_ago > ma_3min_ago:
                    print("2-3 min future trend: UP")
                    # Give 4 min advance notice if not already given
                    if not notice_given:
                        print(f"NOTICE: Prepare to BUY in 4 minutes! ({now.strftime('%Y-%m-%d %H:%M:%S')})")
                        notice_given = True
                elif ma_2min_ago < ma_3min_ago:
                    print("2-3 min future trend: DOWN")
                    notice_given = False
                else:
                    print("2-3 min future trend: FLAT")
                    notice_given = False

            # --- Logging and Display ---
            # Win likelihood: track if previous prediction was correct
            if len(prediction_results) > 0:
                prev_prediction = predictions[-2]
                prev_price = prices[-2]
                # If previous prediction was UP and price increased, or DOWN and price decreased
                if prev_prediction == 'UP' and price_binance > prev_price:
                    prediction_results.append(1)
                elif prev_prediction == 'DOWN' and price_binance < prev_price:
                    prediction_results.append(1)
                elif prev_prediction == 'FLAT' and abs(price_binance - prev_price) < 0.0001:
                    prediction_results.append(1)
                else:
                    prediction_results.append(0)
            # Calculate win likelihood as rolling average of last 20 predictions
            if len(prediction_results) > 0:
                win_likelihood = sum(prediction_results[-20:]) / min(20, len(prediction_results)) * 100
            else:
                win_likelihood = 0.0

            # --- Pocket Options Simulation ---
            if POCKET_OPTIONS_MODE:
                # Simulate a trade on every buy-in signal
                if len(predictions) > 1 and (predictions[-2] in ['DOWN', 'FLAT']) and (predictions[-1] == 'UP'):
                    if po_trade_open is None:
                        po_trade_open = (now, price_binance)
                # Check if trade should close
                if po_trade_open:
                    buy_time, buy_price = po_trade_open
                    if (now - buy_time).total_seconds() >= po_trade_duration:
                        sell_time = now
                        sell_price = price_binance
                        result = 'WIN' if sell_price > buy_price else 'LOSS'
                        po_trades.append((buy_time, buy_price, sell_time, sell_price, result))
                        po_trade_open = None

            # Update plot
            ax.clear()
            ax.plot(timestamps, prices, label=f'Binance {binance_symbol}')
            ax.set_xlabel('Time')
            ax.set_ylabel(f'{symbol} Price (USD)')
            ax.set_title('Live Price & Prediction')
            ax.legend()
            # Draw up/down arrow
            if len(prices) > 1:
                if prediction == 'UP':
                    ax.annotate('', xy=(timestamps[-1], prices[-1]+20), xytext=(timestamps[-1], prices[-1]-20),
                                arrowprops=dict(facecolor='green', shrink=0.05, width=5, headwidth=15))
                elif prediction == 'DOWN':
                    ax.annotate('', xy=(timestamps[-1], prices[-1]-20), xytext=(timestamps[-1], prices[-1]+20),
                                arrowprops=dict(facecolor='red', shrink=0.05, width=5, headwidth=15))
            # Mark buy-in points
            if buy_in_points:
                buy_times, buy_prices = zip(*buy_in_points)
                ax.scatter(buy_times, buy_prices, color='lime', s=80, marker='o', label='Buy-In Signal', zorder=5)
                for t, p in buy_in_points:
                    ax.annotate('BUY', xy=(t, p), xytext=(0, 10), textcoords='offset points', color='green', fontsize=9, fontweight='bold')
            # Pocket Options trade markers
            if POCKET_OPTIONS_MODE and po_trades:
                for trade in po_trades:
                    buy_time, buy_price, sell_time, sell_price, result = trade
                    color = 'blue' if result == 'WIN' else 'red'
                    ax.scatter([buy_time, sell_time], [buy_price, sell_price], color=color, s=60, marker='x', zorder=6)
                    ax.annotate(result, xy=(sell_time, sell_price), xytext=(0, 15), textcoords='offset points', color=color, fontsize=9, fontweight='bold')
            # Show overlays: confidence, win likelihood, profit/loss, PO stats
            overlay_text = f'Conf: {confidence:.1f}%\nWin: {win_likelihood:.1f}%'
            if buy_in_price:
                overlay_text += f"\nProfit: ${profit:+.2f}"
            if POCKET_OPTIONS_MODE:
                wins = sum(1 for t in po_trades if t[-1] == 'WIN')
                losses = sum(1 for t in po_trades if t[-1] == 'LOSS')
                po_balance = 0
                for t in po_trades:
                    if t[-1] == 'WIN':
                        po_balance += investment * po_profit_pct
                    else:
                        po_balance -= investment
                overlay_text += f"\nPO Trades: {len(po_trades)} W:{wins} L:{losses}\nPO Balance: ${po_balance:.2f}"
            ax.text(0.01, 0.97, overlay_text, transform=ax.transAxes, fontsize=10, verticalalignment='top', bbox=dict(facecolor='white', alpha=0.7, edgecolor='gray'))
            plt.xticks(rotation=45, ha='right')
            plt.tight_layout()

            time.sleep(5)  # Wait before next update

        except Exception as e:
            print(f"Error: {e}")
            logging.error(f"Error: {e}")
            time.sleep(5)  # Wait before retrying

plt.ioff()
plt.show()

def auto_fix_error(e):
    error_str = str(e)
    logging.error(f'Auto-fix attempt for error: {error_str}')
    print(f"\n[AI Auto-Fix] Detected error: {error_str}")
    # Example: handle missing package
    if 'No module named' in error_str:
        pkg = error_str.split('No module named ')[-1].replace("'", "").strip()
        print(f"[AI Auto-Fix] Missing package detected: {pkg}")
        user_input = input(f"Do you want to auto-install '{pkg}'? (y/n): ").strip().lower()
        if user_input == 'y':
            try:
                subprocess.check_call([sys.executable, '-m', 'pip', 'install', pkg])
                print(f"[AI Auto-Fix] Successfully installed {pkg}. Please restart the script.")
                logging.info(f"Auto-installed missing package: {pkg}")
            except Exception as install_err:
                print(f"[AI Auto-Fix] Failed to install {pkg}: {install_err}")
                logging.error(f"Failed to auto-install {pkg}: {install_err}")
        else:
            print(f"[AI Auto-Fix] Skipped auto-install for {pkg}.")
    # Add more auto-fix patterns here as needed
    else:
        print("[AI Auto-Fix] No automatic fix available. Please check the logs for details.")

if __name__ == "__main__":
    run_predictor()
 