import random
import time

GRID_SIZE = 5
NUM_MINES = 5
NUM_GEMS = 3

print("=== Mine Guesser ===")
print(f"Grid: {GRID_SIZE}x{GRID_SIZE} | Mines: {NUM_MINES} | Gems: {NUM_GEMS}")

# Generate grid
cells = [(r, c) for r in range(GRID_SIZE) for c in range(GRID_SIZE)]
mines = set(random.sample(cells, NUM_MINES))
gems = set(random.sample([c for c in cells if c not in mines], NUM_GEMS))

# Overlay function
def print_overlay():
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

print_overlay()

while True:
    guess = input("Enter cell to guess (row,col) or 'q' to quit: ").strip().lower()
    if guess == 'q':
        print("Thanks for playing!")
        break
    try:
        row, col = map(int, guess.split(','))
        if (row, col) in mines:
            print("BOOM! You hit a mine at", (row, col))
        elif (row, col) in gems:
            print("Congrats! You found a gem at", (row, col))
        else:
            print("Safe. Nothing here.")
    except Exception:
        print("Invalid input. Please enter as row,col (e.g., 2,3)")
    time.sleep(1)
    print_overlay()
