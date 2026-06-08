#!/bin/bash
# VARIABLES GLOBALES

declare -i tempsDepart=0   # Stocke le chrono (secondes depuis epoch) à partir du début de la partie
declare -i nbrReponsesCorrectes=0        # Compteur de réponses correctes
declare -i nbrCaracteresDonnes=0        # Compteur total de caractères proposés
declare -i precision=0        # Pourcentage des réponses correctes

function finDuJeu() 
{
  local tempsEcoule=$(date +%s)                   # Récupère le chrono en secondes en temps réel
  local dureeTotale=$((tempsEcoule - tempsDepart))  # Calcule la durée totale écoulée

  # Évite une division par zéro si aucun caractère n'a été proposé
  if [ $nbrCaracteresDonnes -eq 0 ]; then
    precision=0
  else
    precision=$((nbrReponsesCorrectes * 100 / nbrCaracteresDonnes))
  fi

  echo -ne "\033[0m"    # Réinitialise toutes les couleures et textes du terminal
  clear                 # Efface tout l'écran

  # Affichage du tableau final avec toutes les statistiques
  echo -e "\033[1;37m"
  echo "========================================"
  echo "       JEU DE FRAPPE - RESULTATS"
  echo "========================================\n"
  echo "  Total time:        ${dureeTotale} seconds"
  echo "  Total attempts:    ${nbrCaracteresDonnes}"
  echo "  Correct answers:   ${nbrReponsesCorrectes}"
  echo "  precision:         ${precision}%"
  echo "========================================"
  echo -e "\033[0m"       # Remet les couleurs par défaut
  exit 0
}

# ecranDAccueil : écran d'accueil avec des '0' et '1'
# Les '0' deviennent des espaces, les '1' deviennent des '$' rouges.

function ecranDAccueil() 
{
  # Chaque ligne de l'image fait exactement 65 caractères (line_char_count).
  declare -r str='
0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000
1000000010000000101111101000000111100111000000100000001000001111
0100000101000001001000001000001000001000100001010000010100001000
0010001000100010001111101000001000001000100010001000100010001111
0001010000010100001000001000001000001000100100000101000001001000
0000100000001000001111101111100111100111001000000010000000101111
0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000
0000000000011110000000100000000001000000010000001111100000000000
0000000000100000000001010000000010100000101000001000000000000000
0000000000100011000011111000000100010001000100001111100000000000
0000000000100001000100000100001000001010000010001000000000000000
0000000000011110010000000100100000001000000001001111100000000000
0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000'

  declare -i row=3          # Ligne de début pour l'affichage (3e ligne)
  line_char_count=65        # Nombre de caractères par "ligne" dans la chaîne brute

  # Positionne le curseur à la ligne 5, colonne 3
  #Le cadre (dessinerBordure) occupe tout l'écran : première/dernière ligne, bords gauche/droite.
  #La ligne 5 évite de chevaucher le cadre supérieur et laisse de la place. Commencer à colonne 3 est plus esthétique
  echo -ne "\033[1;37m\033[5;3H"

  # Parcourt chaque caractère de la chaîne str (indice i)
  for ((i = 0; i < ${#str}; i++)); do
    # Si on arrive à la fin d'une ligne multiple de 65 et que ce n'est pas le premier,
    # on passe à la ligne suivante (row+1) et on repositionne le curseur à la colonne 3.
    if [ "$((i % line_char_count))" == "0" ] && [ "$i" != "0" ]; then
      row=$row+1
      echo -ne "\033["$row";3H"
    fi
    # Caractère '0' affiche un espace
    if [ "${str:$i:1}" == "0" ]; then
      echo -ne "\033[1;37m "
    # Caractère '1' affiche un '$' en rouge clair (code 91)
    elif [ "${str:$i:1}" == "1" ]; then
      echo -ne "\033[1;91m$"
    fi
  done
}

# Variable globale contenant le temps limite pour taper un caractère selon le choix du mode (easy=3, normal=2, difficult=1)
declare -i time

function mode() 
{
  # Trois options
  echo -e "\033[1;37m\033[8;30H1) easy mode"
  echo -e "\033[1;37m\033[9;30H2) normal mode"
  echo -e "\033[1;37m\033[10;30H3) difficult mode"
  echo -ne "\033[22;2H input your choice: "  # Curseur ligne 22, colonne 2
  read mode
  case $mode in
    "1") time=10; menu ;;   # Facile : 3 secondes par caractère
    "2") time=5; menu ;;    # Normal : 2 secondes
    "3") time=3; menu ;;    # Difficile : 1 secondes
    *) echo -e "\033[22;2HYour choice is incorrect, try again"; sleep 1 ;;
  esac
}

function menu() 
{
  while [ 1 ]; do                   # Boucle infinie jusqu'à ce que l'utilisateur quitte en appuyant Ctrl+C
    dessinerBordure                 # Dessin du cadre tout autour de l'écran
    echo -e "\033[1;37m\033[8;30H1) Practice typing numbers"
    echo -e "\033[1;37m\033[9;30H2) Practice typing letters"
    echo -e "\033[1;37m\033[10;30H3) Practice typing alphanumeric characters"
    echo -e "\033[1;37m\033[11;30H4) Practice typing words"
    echo -e "\033[1;37m\033[12;30H5) Quit"
    echo -ne "\033[22;2H input your choice: "
    read choice
    case $choice in
      "1") dessinerBordure; main digit ;;          # Chiffres seulement
      "2") dessinerBordure; main char ;;           # Lettres seulement
      "3") dessinerBordure; main mix ;;            # Alphanumérique
      "4")
        dessinerBordure
        echo -ne "\033[22;2H"
        read -p "Which file would you like to use for typing practice: " file
        if [ ! -f "$file" ]; then               # Si le fichier n'existe pas, revient au menu
          menu
        else
          exec 4< $file                         # Ouvre le fichier en lecture sur le descripteur 4
          main word                             # Appel du jeu en mode "mots"
        fi
        ;;
      "5" | "q" | "Q")
        echo -ne "\033[0m"
        clear
        echo -e "\033[1;37m"
        echo "Goodbye!"
        echo -e "\033[0m"
        exit 0
        ;;
      *) dessinerBordure; echo -e "\033[22;2HError,  try again"; sleep 1 ;;
    esac
  done
}

function dessinerBordure() 
{
  declare -i width
  declare -i high
  width=79 #largeur 79, hauteur 23
  high=23
  clear
  echo -ne "\033[0m"
  # Remplit tout l'écran d'espaces (pour effacer d'anciennes traces)
  for ((i = 1; i <= $width; i = i + 1)); do
    for ((j = 1; j <= $high; j = j + 1)); do
      echo -ne "\033["$j";"$i"H "   # Positionne le curseur en (j,i) et écrit un espace
    done
  done
  # Affiche les quatre coins '+'
  echo -e "\033[1;37m\033[1;1H+\033["$high";1H+\033[1;"$width"H+\033["$high";"$width"H+"
  # Bordures horizontales (lignes de tirets '-')
  for ((i = 2; i <= $width - 1; i = i + 1)); do
    echo -e "\033[1;"$i"H-"
    echo -e "\033["$high";"$i"H-"
  done
  # Bordures verticales (barres '|')
  for ((i = 2; i <= $high - 1; i = i + 1)); do
    echo -e "\033["$i";1H|"
    echo -e "\033["$i";"$width"H|"
  done
}

function effacer() 
{
  local i
  for ((i = 5; i <= 21; i++)); do          # Pour chaque ligne de 5 à 21
    for ((j = $1; j <= $1 + 10; j = j + 1)); do   # Pour chaque colonne sur 10 positions
      echo -ne "\033["$i";"$j"H "          # Se place à (i,j) et écrit un espace
    done
  done
}

function effacerMot() 
{
  local old_row col word
  word=$1
  col=$2
  old_row=$3
  # Pour chaque caractère du mot, on efface à l'emplacement (old_row, col + k)
  for ((k = 0; k < ${#word}; k++)); do
    echo -ne "\033["$old_row";$(($col + $k))H "
  done
}

function move() 
{
  local locate_row lastloca word col
  word=$1
  col=$2
  locate_row=$(($3 + 5))   # Le mot descend de 5 cases par seconde environ

  echo -ne "\033["$locate_row";"$col"H\033[1;97m$word\033[0m"

  # Si ce n'est pas la première frame (temps > 0), efface l'ancienne position
  if [ "$3" -gt "0" ]; then
    lastloca=$(($locate_row - 1))
    effacerMot "$word" "$col" "$lastloca"
  fi
}

function caracteres() 
{
  local chars
  case $1 in
    digit)
      chars='0123456789'
      for ((i = 0; i < 10; i++)); do
        array[$i]=${chars:$i:1}
      done
      ;;
    char)
      chars='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
      for ((i = 0; i < 52; i++)); do
        array[$i]=${chars:$i:1}
      done
      ;;
    mix)
      chars='0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
      for ((i = 0; i < 62; i++)); do
        array[$i]=${chars:$i:1}
      done
      ;;
    *) ;;
  esac
}

function characterRandom() 
{
  local typenum
  declare -i typenum=0
  case $1 in
    digit) typenum=$(($RANDOM % 10)) ;;
    char) typenum=$(($RANDOM % 52)) ;;
    mix) typenum=$(($RANDOM % 62)) ;;
    *) ;;
  esac
  random_char=${array[$typenum]}
}

function main() 
{
  declare -i gamedonetime=0    # Temps écoulé depuis le début
  declare -i starttime         # Chrono de début pour chaque caractère
  declare -i curtime           # Timestamp courant
  declare -i donetime          # Durée écoulée pour un caractère
  precision=0
  caracteres $1                # Prépare le tableau de caractères selon le mode
  tempsDepart=$(date +%s)      # Démarre le chronomètre global

  trap finDuJeu SIGINT         # Redirige Ctrl+C vers la fonction finDuJeu

  while [ 1 ]; do
    echo -e "\033[1;37m\033[2;2H Enter the letter on the screen before it disappears!"
    echo -e "\033[1;37m\033[3;2H Game time:     "
    curtime=$(date +%s)
    gamedonetime=$curtime-$tempsDepart
    echo -e "\033[1;91m\033[3;15H$gamedonetime s\033[1;37m"
    echo -e "\033[1;37m\033[3;60H Total: \033[1;91m$nbrCaracteresDonnes\033[1;37m"
    echo -e "\033[1;37m\033[3;30H precision: \033[1;91m$precision %\033[1;37m"
    echo -ne "\033[1;37m\033[22;2H Your input:                         "

    #Pour le mode mots, on nettoie toute la zone de jeu avant chaque itération
    if [ "$1" == "word" ]; then
      reinitialiser
    fi

    for ((line = 20; line <= 60; line = line + 10)); do
      if [ "${ifchar[$line]}" == "" ] || [ "${donetime[$line]}" -gt "$time" ]; then
        effacer $line                     # Nettoie la zone pour ce caractère
        if [ "$1" == "word" ]; then
          read -u 4 word                     # Lit un mot depuis le fichier
          if [ "$word" == "" ]; then
            exec 4< $file
          fi
          putchar[$line]=$word
        else
          characterRandom $1                 # Tirage de caractère aléatoire
          putchar[$line]=$random_char
        fi
        nbrCaracteresDonnes=$nbrCaracteresDonnes+1                 # Incrémente le compteur total
        ifchar[$line]=1                      # Marque que cette colonne est occupée
        starttime[$line]=$(date +%s)         # Enregistre le moment d'apparition
        curtime[$line]=${starttime[$line]}
        donetime[$line]=$time                # Initialise le temps restant
        column[$line]=0
        if [ "$1" == "word" ]; then
          move "${putchar[$line]}" $line 0    # Affiche le mot tout en haut
        fi
      else
        curtime[$line]=$(date +%s)
        donetime[$line]=${curtime[$line]}-${starttime[$line]}
        move "${putchar[$line]}" $line ${donetime[$line]}   # Anime la descente
      fi
    done

    #Gestion de la saisie utilisateur
    if [ "$1" != "word" ]; then
      # Mode caractère : lecture d'un seul caractère
      echo -ne "\033[1;37m\033[22;14H"
      if read -n 1 -t 0.5 tmp; then
        for ((line = 20; line <= 60; line = line + 10)); do
          if [ "$tmp" == "${putchar[$line]}" ]; then
            effacer $line
            ifchar[$line]=""
            echo -e "\007\033[1;92m\033[4;62H         right !\033[1;37m"
            nbrReponsesCorrectes=$nbrReponsesCorrectes+1
            break
          else
            echo -e "\033[1;91m\033[4;62Hwrong,try again!\033[1;37m"
          fi
        done
      fi
    else
      # Mode mots : lecture d'une ligne complète
      echo -ne "\033[1;37m\033[22;14H"
      if read tmp; then
        for ((line = 20; line <= 60; line = line + 10)); do
          if [ "$tmp" == "${putchar[$line]}" ]; then
            effacer $line
            ifchar[$line]=""
            echo -e "\007\033[1;92m\033[4;62H         right !\033[1;37m"
            nbrReponsesCorrectes=$nbrReponsesCorrectes+1
            break
          else
            echo -e "\033[1;91m\033[4;62Hwrong,try again!\033[1;37m"
          fi
        done
      fi
    fi

    # Mise à jour de la précision après chaque tentative
    if [ $nbrCaracteresDonnes -gt 0 ]; then
      precision=$((nbrReponsesCorrectes * 100 / nbrCaracteresDonnes))
    fi
  done
}

# reinitialiser : Efface toute la zone de jeu (lignes 5 à 21, colonnes 3 à 77)

function reinitialiser() 
{
  local i j
  for ((i = 5; i <= 21; i++)); do
    for ((j = 3; j <= 77; j = j + 1)); do
      echo -ne "\033["$i";"$j"H "
    done
  done
}

dessinerBordure          # Affiche le cadre
ecranDAccueil          # Affiche l'écran d'accueil artistique
echo -ne "\033[1;37m\033[3;30Hstart the game. Y/N : "
read yourchoice
if [ "$yourchoice" == "Y" ] || [ "$yourchoice" == "y" ]; then
  dessinerBordure
  mode         # Lance le choix du mode, puis le menu, puis le jeu
else
  echo -ne "\033[0m"
  clear
  exit 0
fi

exit 0
