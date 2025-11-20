#!/usr/bin/env python3

from random import choice, randint
from words_lib import *
import sys



def get_passes(count):

	rep = {
		'a':'о',
		'е':'и',
		'и':'е',
		'о':'а',
		'п':'б',
		'б':'п'
	}

	rep2 = {
		'й':'q',
		'ц':'w',
		'у':'e',
		'к':'r',
		'е':'t',
		'н':'y',
		'г':'u',
		'ш':'i',
		'щ':'o',
		'з':'p',
		'х':'[',
		'ъ':']',
		'ф':'a',
		'ы':'s',
		'в':'d',
		'а':'f',
		'п':'g',
		'р':'h',
		'о':'j',
		'л':'k',
		'д':'l',
		'ж':';',
		'э':'\'',
		'я':'z',
		'ч':'x',
		'с':'c',
		'м':'v',
		'и':'b',
		'т':'n',
		'ь':'m',
		'б':',',
		'ю':'.',
		'Й':'Q',
		'Ц':'W',
		'У':'E',
		'К':'R',
		'Е':'T',
		'Н':'Y',
		'Г':'U',
		'Ш':'I',
		'Щ':'O',
		'З':'P',
		'Х':'{',
		'Ъ':'}',
		'Ф':'A',
		'Ы':'S',
		'В':'D',
		'А':'F',
		'П':'G',
		'Р':'H',
		'О':'J',
		'Л':'K',
		'Д':'L',
		'Ж':':',
		'Э':'\"',
		'Я':'Z',
		'Ч':'X',
		'С':'C',
		'М':'V',
		'И':'B',
		'Т':'N',
		'Ь':'M',
		'Б':'<',
		'Ю':'>'
	}


	for iterarion in range(count if count else 1):
		first_word = choice(l1)
		last_word = choice(l2)
		p = f'{first_word}{randint(100,999)}{last_word}'
		
		password = ''
		for i in range(len(p)):
			rand1 = randint(0,4)
			rand2 = randint(5,9)
			rand3 = randint(10,14)
			if i == rand1 or i == rand2 or i == rand3:
				password += p[i].upper()
			else:
				password += p[i]

		password2 = ''
		count = 0
		for i in password:
			if i in rep.keys() and count == 0:
				password2 += rep[i]
				count += 1
			else:
				password2 += i

		password3 = ''
		for i in password2:
			if i in rep2.keys() and rep2.keys() != 'э' and rep2.keys() != 'ё':
				password3 += rep2[i]
			else:
				password3 += i


		print(password2, ", ", password3)



if __name__ == "__main__":
    if len(sys.argv) == 1:
        # Если аргументов нет, генерируем 1 пароль
        get_passes(1)
    elif len(sys.argv) == 2:
        # Если есть один аргумент, передаем его в функцию
        get_passes(int(sys.argv[1]))
    else:
        print("Использование:")
        print("  python3 get_nice_pass.py              # Получить 1 пароль")
        print("  python3 get_nice_pass.py 12           # Получить 12 паролей")
        sys.exit(1)
