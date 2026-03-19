#!/bin/bash

secret_number=$(( RANDOM % 1000 + 1 ))

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

is_integer() {
  if [[ $1 =~ ^[0-9]+$ ]]; then
    return 0
  else
    return 1
  fi
}

echo "Enter your username:"
read username

user_info=$($PSQL "SELECT user_id, games_played, best_game FROM users WHERE username='$username'")

if [[ -z $user_info ]]; then
  echo "Welcome, $username! It looks like this is your first time here."
  $PSQL "INSERT INTO users(username, games_played, best_game) VALUES('$username', 0, NULL)" > /dev/null
else
  IFS='|' read -r user_id games_played best_game <<< "$user_info"
  echo "Welcome back, $username! You have played $games_played games, and your best game took $best_game guesses."
fi

echo "Guess the secret number between 1 and 1000:"
guess_count=0

while true; do
  read guess
  ((guess_count++))
  
  if ! is_integer "$guess"; then
    echo "That is not an integer, guess again:"
    continue
  fi
  
  if [[ $guess -eq $secret_number ]]; then
    echo "You guessed it in $guess_count tries. The secret number was $secret_number. Nice job!"
    
    if [[ -z $user_info ]]; then
      $PSQL "UPDATE users SET games_played = 1, best_game = $guess_count WHERE username='$username'" > /dev/null
    else
      new_games_played=$((games_played + 1))
      
      if [[ -z $best_game ]] || [[ $guess_count -lt $best_game ]]; then
        $PSQL "UPDATE users SET games_played = $new_games_played, best_game = $guess_count WHERE username='$username'" > /dev/null
      else
        $PSQL "UPDATE users SET games_played = $new_games_played WHERE username='$username'" > /dev/null
      fi
    fi
    
    break
  elif [[ $guess -gt $secret_number ]]; then
    echo "It's lower than that, guess again:"
  else
    echo "It's higher than that, guess again:"
  fi
done