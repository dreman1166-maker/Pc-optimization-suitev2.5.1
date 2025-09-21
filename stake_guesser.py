import random
import time
import hashlib
import sys
import json
from colorama import init, Fore, Style
init(autoreset=True)

def cprint(text, color=None): 
    if color:
        print(getattr(Fore, color.upper(), '') + text + Style.RESET_ALL)
    else:
        print(text)

def show_help():
    print("\n=== Stake Guesser Help Menu ===")
    print("h/l: Guess HIGH/LOW")
    print("o: Show overlay")
    print("n: Paste next server hash")
    print("b: Change bet amount")
    print("r: Reset game")
    print("e: Export history to text file")
    print("j: Export history to JSON file")
    print("a: Auto-play mode")
    print("u: Undo last round")
    print("s: Show session summary")
    print("v: View full round history")
    print("d: Daily challenge mode")
    print("z: Toggle sound on/off")
    print("g: Customize overlay grid/mines/gems")
    print("save: Save session | load: Load session")
    print("url: Paste Stake.us game URL")
    print("games: List and switch Stake.us games")
    print("dt: Play Dragon Tower mode")
    print("egg: Easter egg | q: Quit game")
    print("help/?: Show this help menu\n")

def save_session(filename="stake_guesser_save.json"):
    with open(filename, 'w') as f:
        json.dump({
            'history': history,
            'balance': balance,
            'round_num': round_num,
            'win_streak': win_streak,
            'loss_streak': loss_streak,
            'max_win_streak': max_win_streak,
            'max_loss_streak': max_loss_streak,
            # 'achievements': list(achievements),
            'client_seed': client_seed,
            'server_hash': server_hash,
            'bet_amount': bet_amount
        }, f)
    print("Session saved.")

def load_session(filename="stake_guesser_save.json"):
    global history, balance, round_num, win_streak, loss_streak, max_win_streak, max_loss_streak, client_seed, server_hash, bet_amount
    try:
        with open(filename, 'r') as f:
            data = json.load(f)
            history = data['history']
            balance = data['balance']
            round_num = data['round_num']
            win_streak = data['win_streak']
            loss_streak = data['loss_streak']
            max_win_streak = data['max_win_streak']
            max_loss_streak = data['max_loss_streak']
            # achievements = set(data['achievements'])
            client_seed = data['client_seed']
            server_hash = data['server_hash']
            bet_amount = data['bet_amount']
        print("Session loaded.")
    except Exception:
        print("No saved session found.")

def export_json():
    fname = f"stake_guesser_history_{int(time.time())}.json"
    with open(fname, 'w') as f:
        json.dump(history, f, indent=2)
    print(f"History exported to {fname}")

def daily_challenge_seed():
    today = time.strftime('%Y-%m-%d')
    return hashlib.sha256(today.encode()).hexdigest()[:16]

def daily_challenge():
    global client_seed, server_hash
    client_seed = daily_challenge_seed()
    server_hash = daily_challenge_seed()[::-1]
    print(f"Daily Challenge! Client Seed: {client_seed}, Server Hash: {server_hash}")

def easter_egg():
    cprint("You found an easter egg! 🥚", "YELLOW")

GRID_SIZE = 5
NUM_MINES = 5
NUM_GEMS = 3
sound_on = True

def print_overlay(round_num):
    GRID_SIZE = 5
    NUM_MINES = 24
    NUM_GEMS = 1
    cells = [(r, c) for r in range(GRID_SIZE) for c in range(GRID_SIZE)]
    random.seed(f"{client_seed}:{server_hash}:{round_num}")
    gem = random.choice(cells)
    mines = set(c for c in cells if c != gem)
    print("\nOverlay:")
    for r in range(GRID_SIZE):
        row = []
        for c in range(GRID_SIZE):
            if (r, c) == gem:
                row.append('�')
            else:
                row.append('�')
        print(' '.join(row))
    print(f"\nGem is at row {gem[0]+1}, column {gem[1]+1}")
    print()
    random.seed()

def customize_overlay():
    global GRID_SIZE, NUM_MINES, NUM_GEMS
    try:
        GRID_SIZE = int(input("Grid size (default 5): ") or 5)
        NUM_MINES = int(input("Number of mines (default 5): ") or 5)
        NUM_GEMS = int(input("Number of gems (default 3): ") or 3)
        print(f"Overlay set to {GRID_SIZE}x{GRID_SIZE}, {NUM_MINES} mines, {NUM_GEMS} gems.")
    except Exception:
        print("Invalid input. Using defaults.")

def toggle_sound():
    global sound_on
    sound_on = not sound_on
    print(f"Sound {'ON' if sound_on else 'OFF'}.")

def play_sound(win):
    if not sound_on:
        return
    try:
        if win:
            winsound.Beep(880, 200)
        else:
            winsound.Beep(220, 200)
    except Exception:
        pass

def advanced_stats():
    if not history:
        print("No stats yet.")
        return
    win_rounds = [h for h in history if h['result'] == 'WIN']
    loss_rounds = [h for h in history if h['result'] == 'LOSS']
    print(f"Longest win streak: {max_win_streak}")
    print(f"Longest loss streak: {max_loss_streak}")
    print(f"Average win: {sum(h['balance'] for h in win_rounds)/len(win_rounds):.2f}" if win_rounds else "No wins yet.")
    print(f"Average loss: {sum(h['balance'] for h in loss_rounds)/len(loss_rounds):.2f}" if loss_rounds else "No losses yet.")

import os
import json
import winsound

LEADERBOARD_FILE = "stake_guesser_leaderboard.json"
 
import random
import time
import hashlib

print("=== Stake Guesser ===")
print("Guess if the next number will be HIGH or LOW!")

balance = 100.0
bet_amount = 5.0

# Add provably fair seed/hash input
client_seed = input("Paste your Active Client Seed (or leave blank for random): ").strip()

server_hash = input("Paste the Server Hash (or leave blank for random): ").strip()
next_server_hash = None

if not client_seed:
    client_seed = str(random.randint(1, 1_000_000_000))
if not server_hash:
    server_hash = str(random.randint(1, 1_000_000_000))

print(f"Using Client Seed: {client_seed}")
print(f"Using Server Hash: {server_hash}")

def provably_fair_number(client_seed, server_hash, round_num):
    data = f"{client_seed}:{server_hash}:{round_num}"
    hash_val = hashlib.sha256(data.encode()).hexdigest()
    return int(hash_val[:8], 16) % 100 + 1

def play_sound(win):
    try:
        if win:
            winsound.Beep(880, 200)
        else:
            winsound.Beep(220, 200)
    except Exception:
        pass

def load_leaderboard():
    if os.path.exists(LEADERBOARD_FILE):
        with open(LEADERBOARD_FILE, 'r') as f:
            return json.load(f)
    return []

def save_leaderboard(lb):
    with open(LEADERBOARD_FILE, 'w') as f:
        json.dump(lb, f)

def update_leaderboard(name, balance, max_win_streak):
    lb = load_leaderboard()
    lb.append({'name': name, 'balance': balance, 'max_win_streak': max_win_streak})
    lb = sorted(lb, key=lambda x: (-x['balance'], -x['max_win_streak']))[:10]
    save_leaderboard(lb)
    return lb

def print_leaderboard():
    lb = load_leaderboard()
    print("\nLeaderboard (Top 10):")
    for i, entry in enumerate(lb, 1):
        print(f"{i}. {entry['name']} - ${entry['balance']:.2f} | Max Streak: {entry['max_win_streak']}")
    print()



def get_confidence(history, guess):
    # AI-inspired: use last 10 rounds, streaks, and win rate
    if not history:
        return 50.0
    last = history[-10:]
    win_rate = sum(1 for h in last if h['result'] == 'WIN') / len(last) * 100
    high_count = sum(1 for h in last if h['number'] > 50)
    low_count = len(last) - high_count
    if guess == 'h':
        conf = 50 + (high_count - low_count) * 5 + (win_rate - 50) * 0.5
    else:
        conf = 50 + (low_count - high_count) * 5 + (win_rate - 50) * 0.5
    return max(0, min(100, conf))

def smart_suggestion(history):
    if not history:
        return 'h', 50.0
    last = history[-10:]
    high_count = sum(1 for h in last if h['number'] > 50)
    low_count = len(last) - high_count
    if high_count > low_count:
        return 'h', high_count / len(last) * 100
    else:
        return 'l', low_count / len(last) * 100

def print_overlay(round_num):
    GRID_SIZE = 5
    NUM_MINES = 5
    NUM_GEMS = 3
    cells = [(r, c) for r in range(GRID_SIZE) for c in range(GRID_SIZE)]
    random.seed(f"{client_seed}:{server_hash}:{round_num}")
    mines = set(random.sample(cells, NUM_MINES))
    gems = set(random.sample([c for c in cells if c not in mines], NUM_GEMS))
    print("\nOverlay:")
    for r in range(GRID_SIZE):
        row = []
        for c in range(GRID_SIZE):
            if (r, c) in mines:
                row.append('💣')
            elif (r, c) in gems:
                row.append('💎')
            else:
                row.append('.')
        print(' '.join(row))
    print()
    random.seed()

history = []
stake_game_urls = []  # List of saved Stake.us game URLs
active_game_index = None  # Index of the currently active game
round_num = 1
win_streak = 0
loss_streak = 0
max_win_streak = 0
max_loss_streak = 0

while True:
    print(f"\nCurrent balance: ${balance:.2f}")
    print(f"Active Client Seed: {client_seed}")
    print(f"Server Hash: {server_hash}")
    if next_server_hash:
        print(f"Next Server Hash: {next_server_hash}")
    print(f"Current bet: ${bet_amount:.2f}")
    print(f"Win streak: {win_streak} | Loss streak: {loss_streak}")
    print(f"Max win streak: {max_win_streak} | Max loss streak: {max_loss_streak}")
    if history:
        win_rate = sum(1 for h in history if h['result'] == 'WIN') / len(history) * 100
        print(f"Games played: {len(history)} | Win rate: {win_rate:.1f}%")
    suggestion, suggestion_conf = smart_suggestion(history)
    print(f"Smart Suggestion: {'HIGH' if suggestion == 'h' else 'LOW'} ({suggestion_conf:.1f}% recent bias)")
    print_leaderboard()

    if active_game_index is not None and 0 <= active_game_index < len(stake_game_urls):
        print(f"Active Stake.us Game: {stake_game_urls[active_game_index]}")
    guess = input("Will the next number be HIGH (51-100) or LOW (1-50)? (h/l/q to quit, o for overlay, n for next server hash, b to change bet, r to reset, e to export, url to paste game URL, games to switch game, dt for Dragon Tower): ").strip().lower()
    if guess == 'dt':
        # Enhanced Dragon Tower: 8 rows, 5 columns, 1 safe tile per row
        rows, cols = 8, 5
        dragon_grid = []
        safe_tiles = [random.randint(0, cols-1) for _ in range(rows)]
        print("\nDragon Tower! Each row has 1 safe tile. Pick a column (1-5) for each row.")
        dragon_tower_win = True
        dragon_tower_cleared = 0
        dragon_tower_bet = bet_amount
        dragon_tower_reward = 0
        for r in range(rows):
            col_guess = input(f"Row {r+1} - Pick a column (1-5): ").strip()
            try:
                col_idx = int(col_guess) - 1
                if col_idx == safe_tiles[r]:
                    dragon_grid.append('🟩')
                    print("Safe!")
                    dragon_tower_cleared += 1
                    dragon_tower_reward += dragon_tower_bet * 0.5  # Reward increases per row
                else:
                    dragon_grid.append('💀')
                    print(f"Hit a dragon at row {r+1}! Game over.")
                    dragon_tower_win = False
                    break
            except Exception:
                print("Invalid input. Game over.")
                dragon_grid.append('❓')
                dragon_tower_win = False
                break
        if dragon_tower_win and dragon_tower_cleared == rows:
            print("Congratulations! You cleared the Dragon Tower!")
            dragon_tower_reward += dragon_tower_bet  # Bonus for full clear
        print("Dragon Tower result:")
        for i, tile in enumerate(dragon_grid):
            print(f"Row {i+1}: {tile}")
        # Update balance and history
        if dragon_tower_cleared > 0:
            balance += dragon_tower_reward
            print(f"You won ${dragon_tower_reward:.2f} for clearing {dragon_tower_cleared} row(s). New balance: ${balance:.2f}")
        else:
            balance -= dragon_tower_bet
            print(f"You lost your bet of ${dragon_tower_bet:.2f}. New balance: ${balance:.2f}")
        history.append({
            'round': round_num,
            'game': 'Dragon Tower',
            'rows_cleared': dragon_tower_cleared,
            'result': 'WIN' if dragon_tower_win and dragon_tower_cleared == rows else 'LOSS',
            'reward': dragon_tower_reward if dragon_tower_cleared > 0 else -dragon_tower_bet,
            'balance': balance
        })
        round_num += 1
        continue
    if guess == 'url':
        url = input("Paste the Stake.us game URL: ").strip()
        if url:
            stake_game_urls.append(url)
            active_game_index = len(stake_game_urls) - 1
            print(f"Game URL added and set as active: {url}")
        else:
            print("No URL entered.")
        continue
    if guess == 'games':
        if not stake_game_urls:
            print("No Stake.us game URLs saved. Use 'url' to add one.")
        else:
            print("Saved Stake.us Games:")
            for idx, u in enumerate(stake_game_urls):
                marker = "<-- active" if idx == active_game_index else ""
                print(f"{idx+1}. {u} {marker}")
            try:
                sel = input("Enter number to switch active game (or press Enter to keep current): ").strip()
                if sel:
                    sel_idx = int(sel) - 1
                    if 0 <= sel_idx < len(stake_game_urls):
                        active_game_index = sel_idx
                        print(f"Switched to game: {stake_game_urls[active_game_index]}")
                    else:
                        print("Invalid selection.")
            except Exception:
                print("Invalid input.")
        continue
    if guess == 'q':
        print("Thanks for playing!")
        break
    if guess == 'o':
        print_overlay(round_num)
        continue
    if guess == 'n':
        next_server_hash = input("Paste the NEXT Server Hash: ").strip()
        continue
    if guess == 'b':
        try:
            new_bet = float(input("Enter new bet amount: "))
            if new_bet > 0:
                bet_amount = new_bet
                print(f"Bet amount set to ${bet_amount:.2f}")
            else:
                print("Bet must be positive.")
        except Exception:
            print("Invalid bet amount.")
        continue
    if guess == 'r':
        balance = 100.0
        round_num = 1
        win_streak = 0
        loss_streak = 0
        max_win_streak = 0
        max_loss_streak = 0
        history.clear()

        client_seed = input("Paste your Active Client Seed (or leave blank for random): ").strip() or str(random.randint(1, 1_000_000_000))
        server_hash = input("Paste the Server Hash (or leave blank for random): ").strip() or str(random.randint(1, 1_000_000_000))
        print(f"Reset! Using Client Seed: {client_seed}")
        print(f"Using Server Hash: {server_hash}")
        continue
    if guess == 'e':
        fname = f"stake_guesser_history_{int(time.time())}.txt"
        with open(fname, 'w') as f:
            for h in history:
                f.write(str(h) + '\n')
        print(f"History exported to {fname}")
        continue
    if guess not in ['h', 'l']:
        print("Invalid input. Please enter 'h' for HIGH, 'l' for LOW, 'o' for overlay, 'n' for next server hash, 'b' for bet, 'r' to reset, 'e' to export, or 'q' to quit.")
        continue
    if balance < bet_amount:
        print("Not enough balance to bet!")
        break
    # Provably fair number
    number = provably_fair_number(client_seed, server_hash, round_num)
    print(f"The number is: {number}")
    if (guess == 'h' and number > 50) or (guess == 'l' and number <= 50):
        print("You WIN!")
        balance += bet_amount
        result = 'WIN'
        win_streak += 1
        loss_streak = 0
        max_win_streak = max(max_win_streak, win_streak)
    else:
        print("You LOSE!")
        balance -= bet_amount
        result = 'LOSS'
        loss_streak += 1
        win_streak = 0
        max_loss_streak = max(max_loss_streak, loss_streak)
    history.append({
        'round': round_num,
        'guess': guess,
        'number': number,
        'result': result,
        'balance': balance,
        'client_seed': client_seed,
        'server_hash': server_hash,
        'bet': bet_amount
    })
    round_num += 1
    if next_server_hash:
        server_hash = next_server_hash
        next_server_hash = None
    time.sleep(1)

# The end
