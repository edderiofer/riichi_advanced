[["flower", "1z", "2z", "3z", "4z", "0z", "6z", "7z"], []] as $to_remove
|
.play_restrictions |= map(select(. != $to_remove))
