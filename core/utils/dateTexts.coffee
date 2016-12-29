module.exports = ->
    dayNames: [
        s("Dimanche")
        s("Lundi")
        s("Mardi")
        s("Mercredi")
        s("Jeudi")
        s("Vendredi")
        s("Samedi")
    ]
    dayNamesShort: [
        s("Dim")
        s("Lun")
        s("Mar")
        s("Mer")
        s("Jeu")
        s("Ven")
        s("Sam")
    ]
    monthNames: [
        s("Janvier")
        s("Février")
        s("Mars")
        s("Avril")
        s("Mai")
        s("Juin")
        s("Juillet")
        s("Août")
        s("Septembre")
        s("Octobre")
        s("Novembre")
        s("Décembre")
    ]
    monthNamesShort: [
        s("Jan")
        s("Fév")
        s("Mar")
        s("Avr")
        s("Mai")
        s("Jui")
        s("Jul")
        s("Aoû")
        s("Sep")
        s("Oct")
        s("Nov")
        s("Déc")
    ]
    closeText: s("Fermer")
    prevText: s("Précédent")
    nextText: s("Suivant")
    currentText: s("Aujourd'hui")
    #monthNames: ["janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août", "septembre", "octobre", "novembre", "décembre"]
    #monthNamesShort: ["janv.", "févr.", "mars", "avril", "mai", "juin", "juil.", "août", "sept.", "oct.", "nov.", "déc."]
    #dayNames: ["dimanche", "lundi", "mardi", "mercredi", "jeudi", "vendredi", "samedi"]
    #dayNamesShort: ["dim.", "lun.", "mar.", "mer.", "jeu.", "ven.", "sam."]
    dayNamesMin: s("D L M M J V S").split(/\s/g)
    weekHeader: s("Sem.")
    dateFormat: s("dd/mm/yy")
    firstDay: 1
    isRTL: false
    showMonthAfterYear: false
    yearSuffix: ""
    longDateFormat:
        LT: s("HH:mm")
        L: s("DD/MM/YYYY")
        LL: s("D MMMM YYYY")
        LLL: s("D MMMM YYYY LT")
        LLLL: s("dddd D MMMM YYYY LT")
    defaultButtonText:
        month: s("Mois")
        week: s("Semaine")
        day: s("Jour")
        list: s("Mon planning")
    allDayHTML: s("Toute la journée")
    allDayText: s("Journée")
    axisFormat: s("H'h'mm") # "h(:mm)tt"
    timeFormat:
        agenda: s("H:mm{ - H:mm}")
    titleFormat:
        month: s("MMMM yyyy")
        week: s("d MMM [ yyyy]{ {dash} d [ MMM] yyyy}" #"MMM d[ yyyy]{ {dash} [ MMM] d yyyy}"
            dash: "'&#8212;'"
        )
        day: s("dddd d MMM yyyy") #"dddd, MMM d, yyyy"
    shortTimeFormat: s("H'h'(:mm)") #"h(:mm)t"
    columnFormat:
        month: s("ddd")
        week: s("ddd d/M") #"ddd M/d"
        day: s("dddd d/M") #"dddd M/d"
    buttonText:
        today: s("aujourd'hui")