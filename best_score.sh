for x in mono tri1 tri2 tri3; do
  cat /home/user2/Aditya/digits_IIIT/exp/$x/decode/wer_* | utils/best_wer.sh >> RESULTS
done
