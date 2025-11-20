head /dev/urandom | LC_ALL=C tr -dc 'A-Za-z0-9' | head -c 32 && echo

autoload -U zmv
zmv  '(**/)\[SSL.BAND\] (*)' '$1$2'

