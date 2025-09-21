import os
import discord
from discord.ext import commands, tasks
import asyncio

# Replace with your bot token and channel ID
discord_token = 'YOUR_DISCORD_BOT_TOKEN_HERE'
signal_channel_id = 1047899575098290196  # Set to your Discord channel ID


# Import your crypto predictor function here
import sys
import importlib.util
import threading

# Start the predictor in a background thread
spec = importlib.util.spec_from_file_location("crypto_predictor", "c:/Users/drema/AutoKey/crypto_predictor.py")
crypto_predictor = importlib.util.module_from_spec(spec)
sys.modules["crypto_predictor"] = crypto_predictor
spec.loader.exec_module(crypto_predictor)

def start_predictor():
    crypto_predictor.run_predictor()

predictor_thread = threading.Thread(target=start_predictor, daemon=True)
predictor_thread.start()

def get_latest_signal():
    return crypto_predictor.get_latest_signal()

intents = discord.Intents.default()
bot = commands.Bot(command_prefix='!', intents=intents)

@bot.event
def on_ready():
    print(f'Logged in as {bot.user}')
    send_signal.start()

@tasks.loop(minutes=5)
async def send_signal():
    channel = bot.get_channel(signal_channel_id)
    if channel:
        signal = get_latest_signal()
        await channel.send(f"Crypto Signal: {signal}")

@bot.command()
async def signal(ctx):
    signal = get_latest_signal()
    await ctx.send(f"Crypto Signal: {signal}")

if __name__ == "__main__":
    bot.run(discord_token)
