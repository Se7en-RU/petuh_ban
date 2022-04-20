# Petuh ban

По просьбам трудящихся с hlmod. Плагин специфичных банов.
https://hlmod.ru/threads/nakazanie-chiterov.61786/page-2#post-577025

## Зависимости

https://github.com/Franc1sco/First-Person-View-Models-Interface

https://github.com/drixevel-dev/chat-processor
    
## Использование

    #include <petuh_ban>

	if (Petuh_IsPetuh(client)) {
		// Игрок забанен
	}
	
	Petuh_Ban(client); // Забанить игрока
