%{
	#include <stdio.h>
	#include <string.h>
	#include <stdbool.h>
	#include <time.h>
	void yyerror(char* s);

	#define EVT 1
	#define UNIQ 2
	#define REPET 3
	#define JOURN 4
	#define DEBUT 5
	#define FIN 6
	#define DAT 7
	#define TXT 8
	#define DESCR 9
	#define LIEU 10
	#define TITRE 11
	#define ALAR 12
	#define FRE 13
	#define CPT 14
	#define LJ 15
	#define PER 16
	#define LIM 17
	int tab1[1000][5];
	char buffer[100000]="";

	FILE *yyoutput;
	
%}

%token DEBCAL FINCAL DEBEVT FINEVT IDEBEVTU IFINEVTU DATEVTU
%token ITITRE ILIEU IDESCR DEBAL FINAL TRIGGER POSAL TEXTE
%token RRULE FREQ COUNT BYDAY UNTIL WKST VALFREQ PV NOMBRE LISTJ
%token DEBEVTR FINEVTR DEBEVTJ FINEVTJ DATEVTJ DATEVTR
%start fichier
%%

fichier : DEBCAL liste_evenements FINCAL ;
liste_evenements : evenement liste_evenements | ;
evenement : DEBEVT infos_evenement FINEVT ;
infos_evenement : infos_evenement_unique | infos_evenement_repetitif | infos_evenement_journalier ;
infos_evenement_unique : IDEBEVTU DATEVTU {tab1[yylval][1] = DEBUT;} IFINEVTU DATEVTU {tab1[yylval][1] = FIN;} suite_infos_evenement ;
suite_infos_evenement : les_textes liste_alarmes ;
les_textes : IDESCR TEXTE {tab1[yylval][1] = DESCR;} ILIEU TEXTE {tab1[yylval][1] = LIEU;} ITITRE TEXTE {tab1[yylval][1] = TITRE;} ;
infos_evenement_repetitif : DEBEVTR DATEVTR {tab1[yylval][1] = DEBUT;} FINEVTR DATEVTR {tab1[yylval][1] = FIN;} repetition suite_infos_evenement ;
infos_evenement_journalier : DEBEVTJ DATEVTJ {tab1[yylval][1] = DEBUT;} FINEVTJ DATEVTJ {tab1[yylval][1] = FIN;} suite_infos_evenement ;
liste_alarmes : alarme liste_alarmes | ;
alarme : DEBAL TRIGGER POSAL FINAL ;
repetition : RRULE FREQ VALFREQ PV WKST PV COUNT NOMBRE PV BYDAY LISTJ
	| RRULE FREQ VALFREQ PV UNTIL DATEVTU {tab1[yylval][1] = LIM;}
	| RRULE FREQ VALFREQ PV WKST PV UNTIL DATEVTU {tab1[yylval][1] = LIM;}
	| RRULE FREQ VALFREQ PV UNTIL DATEVTU {tab1[yylval][1] = LIM;} PV BYDAY LISTJ
	| RRULE FREQ VALFREQ PV WKST PV UNTIL DATEVTU {tab1[yylval][1] = LIM;} PV BYDAY LISTJ ;
%%

 void yyerror(char* s){
 	fprintf(stdout,"\n Erreur -> %s \n",s);
 	return 0;
 }

bool anneeBis(int date){
    return (date % 4 == 0 && (date % 100 != 0 || date % 400 == 0));
}

bool date_valide(const char *date) {
    int res, year, month, day, hour = 0, minute = 0, second = 0;

	bool b = true;

    if (strchr(date, 'T') != NULL) {
        if (strchr(date, 'Z') != NULL) 
            res = sscanf(date, "%4d%2d%2dT%2d%2d%2dZ", &year, &month, &day, &hour, &minute, &second);
        else 
            res = sscanf(date, "%4d%2d%2dT%2d%2d%2d", &year, &month, &day, &hour, &minute, &second);
    } else
        res = sscanf(date, "%4d%2d%2d", &year, &month, &day);

    b = !(res != 6 || res != 3);

    b = !(year < 0 || month < 1 || month > 12 || day < 1 || hour < 0 || hour > 23 || minute < 0 || minute > 59 || second < 0 || second > 59);

    int jourPM[] = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};

    if (anneeBis(year))
        jourPM[1] = 29;

    b = !(day > jourPM[month - 1]); 

    return b;
}
//Verifie si la date de fin est posterieur à la date du début (pour des dates valides)
bool dateP(const char *dateD, const char *dateF) {
	int yearD, monthD, dayD, hourD = 0, minuteD = 0, secondD = 0;
	int yearF, monthF, dayF, hourF = 0, minuteF = 0, secondF = 0;

	bool b = true;

    if (strchr(dateD, 'T') != NULL) {
        if (strchr(dateD, 'Z') != NULL) 
            sscanf(dateD, "%4d%2d%2dT%2d%2d%2dZ", &yearD, &monthD, &dayD, &hourD, &minuteD, &secondD);
         else 
            sscanf(dateD, "%4d%2d%2dT%2d%2d%2d", &yearD, &monthD, &dayD, &hourD, &minuteD, &secondD);
    } else 
        sscanf(dateD, "%4d%2d%2d", &yearD, &monthD, &dayD);

	if (strchr(dateF, 'T') != NULL) {
		if (strchr(dateF, 'Z') != NULL) 
			sscanf(dateF, "%4d%2d%2dT%2d%2d%2dZ", &yearF, &monthF, &dayF, &hourF, &minuteF, &secondF);
		else 
			sscanf(dateF, "%4d%2d%2dT%2d%2d%2d", &yearF, &monthF, &dayF, &hourF, &minuteF, &secondF);
	} else 
		sscanf(dateF, "%4d%2d%2d", &yearF, &monthF, &dayF);

	b = 
	!(yearD>yearF 
	|| (yearD==yearF && monthD > monthF) 
	|| (yearD==yearF && monthD==monthF && dayD > dayF) 
	|| (yearD==yearF && monthD==monthF && dayD==dayF && hourD > hourF) 
	|| (yearD==yearF && monthD==monthF && dayD==dayF && hourD == hourF && minuteD>minuteF)
	|| (yearD==yearF && monthD==monthF && dayD==dayF && hourD == hourF && minuteD==minuteF && secondD>=secondF));
	
	return b;

}

char* affNb(int nb){
	char* temp = malloc(sizeof(char) * 10);
	if(nb >=0 && nb<=9){
		sprintf(temp, "0%d", nb);
	}
	else{
		sprintf(temp, "%d", nb);
	}
	return temp;
}	

 int main()
 {	
	//Création du fichier
	FILE *htmlpage;
	htmlpage=fopen("index.html","w");
	fprintf(htmlpage,"<html>\n<head>\n");
	fprintf(htmlpage,"<title>Calendrier</title>\n");
	fprintf(htmlpage,"</head>\n");
	fprintf(htmlpage,"<body>\n");

	int i;
 	yyparse();
	//printf("\nFin des analyses lexicale et ssssssssyntaxiquessssss\n");
	char temp[600]="";
	char temp2[600]="";
	bool valide = true;
	//Vérification des dates
	for(i = 0; i < yylval; i++){
		if(tab1[i][0] == DAT){
			strncpy(temp,buffer + tab1[i][3], tab1[i][4]);
			temp[tab1[i][4]] = '\0';
			if(date_valide(temp)){
				//printf("DATE VALIDE \n");
			}
			else{
				//printf("DATE NON VALIDE \n");
				valide=false;
			}
				
		}
	}

	//Vérification date postérieur
	if(valide){
		for(i = 0; i < yylval; i++){
			if(tab1[i][0] == EVT){
				strncpy(temp,buffer + tab1[i+1][3], tab1[i+1][4]);
				strncpy(temp2,buffer + tab1[i+2][3], tab1[i+2][4]);
				temp[tab1[i+1][4]] = '\0';
				temp2[tab1[i+2][4]] = '\0';

				/*if(dateP(temp, temp2))
					//printf("DATE POSTERIEUR \n");
				else{
					//printf("DATE PAS POSTERIEUR \n");
					valide=false;
				}*/
				if(!dateP(temp, temp2))
					valide=false;
				i+=2;
			}
		}
	}
	
	if(valide){
		//Vérification date limite postérieur date début
		for(i = 0; i < yylval; i++){
			if(tab1[i][1] == REPET){
				strncpy(temp,buffer + tab1[i+1][3], tab1[i+1][4]);
				temp[tab1[i+1][4]] = '\0';
				i+=2;
				while(i<yylval && tab1[i][1]!=LIM && tab1[i][0]!=EVT ){
					i++;
				}
				if(i<yylval && tab1[i][1]==LIM){
					strncpy(temp2,buffer + tab1[i][3], tab1[i][4]);
					temp2[tab1[i][4]] = '\0';
					/*if(dateP(temp, temp2))
						//printf("DATE LIMITE POSTERIEUR \n");
					else{
						//printf("DATE LIMITE PAS POSTERIEUR \n");
						valide=false;
					}*/
					if(!dateP(temp, temp2))
						valide=false;
						
				}
				else
					i--;
			}
		}
	}


	//Vérification plusieurs alarmes en même temps -P0DT1H0M0S
	if(valide){
		int nb;
		char alarmesT[500][20];
		for(i = 0; i < yylval; i++){
			if(tab1[i][0] == EVT){
				nb=0;
				i++;
				while(i<yylval && tab1[i][0]!=EVT ){
					if(tab1[i][0] == ALAR){
						strncpy(temp,buffer + tab1[i][3], tab1[i][4]);
						temp[tab1[i][4]] = '\0';
						//printf("%s\n", temp);
						strncpy(alarmesT[nb],temp,strlen(temp));
						nb++;
					}
					i++;
				}
				
				for (int i = 0; i < nb - 1; i++) {
					for (int j = i + 1; j < nb; j++) {
						if (strcmp(alarmesT[i], alarmesT[j]) == 0) {
							valide=false;
							//printf("%s et %s identiques\n",alarmesT[i], alarmesT[j]);
						}
					}
				}
				if(i<yylval && tab1[i][0]==EVT )
					i--;
			}
		}
	}

	if(valide){
		char html[100000]="";
		char info[800]="";
		char loc[600]="";
		char tit[600]="";
		char des[600]="";
		char infFreq[900]="";
		printf("\n\n\n");
		int yearD = 0, monthD = 0, dayD = 0, hourD = 0, minuteD = 0, secondD = 0;
		int yearF = 0, monthF = 0, dayF = 0, hourF = 0, minuteF = 0, secondF = 0;
		int nbU=0, nbR=0, nbJ=0;
		//TRADUCTION
		for(i = 0; i < yylval; i++){
			if(tab1[i][0] == EVT ){
				yearD = 0, monthD = 0, dayD = 0, hourD = 0, minuteD = 0, secondD = 0;
				yearF = 0, monthF = 0, dayF = 0, hourF = 0, minuteF = 0, secondF = 0;
				strncpy(temp,buffer + tab1[i+1][3], tab1[i+1][4]);
				strncpy(temp2,buffer + tab1[i+2][3], tab1[i+2][4]);
				temp[tab1[i+1][4]] = '\0';
				temp2[tab1[i+2][4]] = '\0';
				if((nbU+nbR+nbJ)>0){
					strcat(html,"</p></div>");
				}
				if(tab1[i][1] == UNIQ){
					nbU++;
					sscanf(temp, "%4d%2d%2dT%2d%2d%2dZ", &yearD, &monthD, &dayD, &hourD, &minuteD, &secondD);
					sscanf(temp2, "%4d%2d%2dT%2d%2d%2dZ", &yearF, &monthF, &dayF, &hourF, &minuteF, &secondF);
					sprintf(info,"<div><h1>Du %s/%s/%s %s:%s:%s au %s/%s/%s %s:%s:%s</h1>\n", affNb(dayD), affNb(monthD), affNb(yearD), affNb(hourD), affNb(minuteD), affNb(secondD), affNb(dayF), affNb(monthF), affNb(yearF), affNb(hourF), affNb(minuteF), affNb(secondF));
				}else
				if(tab1[i][1] == REPET){
					nbR++;
					sscanf(temp, "%4d%2d%2dT%2d%2d%2d", &yearD, &monthD, &dayD, &hourD, &minuteD, &secondD);
					sscanf(temp2, "%4d%2d%2dT%2d%2d%2d", &yearF, &monthF, &dayF, &hourF, &minuteF, &secondF);
					sprintf(info,"<div style=\"color:green\"><h1>Du %s/%s/%s %s:%s:%s au %s/%s/%s %s:%s:%s</h1>\n", affNb(dayD), affNb(monthD), affNb(yearD), affNb(hourD), affNb(minuteD), affNb(secondD), affNb(dayF), affNb(monthF), affNb(yearF), affNb(hourF), affNb(minuteF), affNb(secondF));
				}
				else
				if(tab1[i][1] == JOURN){
					nbJ++;
					sscanf(temp, "%4d%2d%2d", &yearD, &monthD, &dayD);
					sscanf(temp2, "%4d%2d%2d", &yearF, &monthF, &dayF);
					sprintf(info,"<div style=\"color:red\"><h1>Le %s/%s/%s, toute la journée</h1>\n", affNb(dayD), affNb(monthD), affNb(yearD));
				}
				strcat(html,info);
				i+=2;
			}
			else
			if(tab1[i][1] == DESCR){
				strncpy(des,buffer + tab1[i][3], tab1[i][4]);
				strncpy(loc,buffer + tab1[i+1][3], tab1[i+1][4]);
				strncpy(tit,buffer + tab1[i+2][3], tab1[i+2][4]);
				des[tab1[i][4]] = '\0';
				loc[tab1[i+1][4]] = '\0';
				tit[tab1[i+2][4]] = '\0';


				if(tab1[i+2][4] == 0)
					sprintf(info, "\t<h2>Pas de titre</h2>\n");
				else
					sprintf(info,"\t<h2>%s</h2>\n", tit);
				strcat(html,info);

				if(tab1[i+1][4] == 0)
					sprintf(info, "\t\t<p>Pas de lieu<br>\n");
				else
					sprintf(info,"\t\t<p>Lieu : %s<br>\n", loc);

				strcat(html,info);

				if(tab1[i][4] == 0)
					sprintf(info, "\t\tPas de description\n");
				else
					sprintf(info,"\t\tDescription : %s\n", des);

				strcat(html,info);

				if(strlen(infFreq)>0){
					strcat(html,infFreq);
					strcpy(infFreq,"\0");
				}

			}
			else
			if(tab1[i][0] == FRE && tab1[i][1] == PER){ //Premier élément de fréquence sera toujours valfreq (daily, weekly...)
				strncpy(temp,buffer + tab1[i][3], tab1[i][4]);
				temp[tab1[i][4]] = '\0';
				sprintf(info, "\t\t<br/>Doit se répéter chaque ");

				if(strcmp(temp, "DAILY") == 0){
					strcat(info, "jour, ");
				}else
				if(strcmp(temp, "WEEKLY") == 0){
					strcat(info, "semaine, ");
				}else
				if(strcmp(temp, "MONTHLY") == 0){
					strcat(info, "mois, ");
				}else
				if(strcmp(temp, "YEARLY") == 0){
					strcat(info, "annnée, ");
				}

				strcat(infFreq,info);

				bool dL = false;
				int j = i;
				while(dL == false && (j<yylval && tab1[j][0]!=EVT)){ //On cherche une date limite
					if(tab1[j][0] == DAT && tab1[j][1] == LIM){
						strncpy(temp,buffer + tab1[j][3], tab1[j][4]);
						temp[tab1[j][4]] = '\0';
						dL = true;
					}
					j++;
				}
				if(dL){
					//Si on a une date limite
					yearD = 0, monthD = 0, dayD = 0, hourD = 0, minuteD = 0, secondD = 0;
					sscanf(temp, "%4d%2d%2dT%2d%2d%2dZ", &yearD, &monthD, &dayD, &hourD, &minuteD, &secondD);
					sprintf(info,"jusqu'au %s/%s/%s à %s:%s:%s\n", affNb(dayD), affNb(monthD), affNb(yearD), affNb(hourD), affNb(minuteD), affNb(secondD));
					strcat(infFreq,info);
				}
				else{
					//On cherche le compteur et le jour
					j = i;
					while(j<yylval && tab1[j][0]!=EVT ){ //Alarme à la fin d'un événement donc on peut rechercher jusqu'à l'autre événement
						if(tab1[j][0] == FRE && tab1[j][1] == CPT){
							strncpy(temp,buffer + tab1[j][3], tab1[j][4]);
							temp[tab1[j][4]] = '\0';
						}
						if(tab1[j][0] == FRE && tab1[j][1] == LJ){
							strncpy(temp2,buffer + tab1[j][3], tab1[j][4]);
							temp2[tab1[j][4]] = '\0';
						}
						j++;
					}

					if(strcmp(temp2, "SU") == 0){
						strcat(infFreq, "les dimanche, ");
					}else
					if(strcmp(temp2, "MO") == 0){
						strcat(infFreq, "les lundi, ");
					}else
					if(strcmp(temp2, "TU") == 0){
						strcat(infFreq, "les mardi, ");
					}else
					if(strcmp(temp2, "WE") == 0){
						strcat(infFreq, "les mercredi, ");
					}else
					if(strcmp(temp2, "TH") == 0){
						strcat(infFreq, "les jeudi, ");
					}else
					if(strcmp(temp2, "FR") == 0){
						strcat(infFreq, "les vendredi, ");
					}else
					if(strcmp(temp2, "SA") == 0){
						strcat(infFreq, "les samedi, ");
					}
					sprintf(info, "%s fois\n", temp);
					strcat(infFreq,info);
				}

			}
			else
			if(tab1[i][0] == ALAR){
				int jA = 0, hA = 0, mA = 0, sA = 0;
				char alarmes[500][20];
				int nb=0;

				while(i<yylval && tab1[i][0]!=EVT ){ //Alarme à la fin d'un événement donc on peut rechercher jusqu'à l'autre événement
					if(tab1[i][0] == ALAR){
						strncpy(temp,buffer + tab1[i][3], tab1[i][4]);
						temp[tab1[i][4]] = '\0';
						strncpy(alarmes[nb],temp,strlen(temp));
						nb++;
					}
					i++;
				}

				if(nb > 0){
					
					strcat(html,"\t\t</br>Alarmes définies : ");
					for (int j = 0; j < nb; j++) {
						sscanf(alarmes[j], "-P%dDT%dH%dM%dS", &jA, &hA, &mA, &sA);
						sprintf(info, "%dH%dM%dS", hA, mA, sA);
						if( j < (nb-1) ){
							strcat(info, ", ");
						} else {
							strcat(info, "\n");
						}
						strcat(html, info);
					}
				}
				if(i<yylval && tab1[i][0]==EVT )
					i--;
			}
		}
		if((nbU+nbR+nbJ)>0){
			strcat(html,"</div>");
		}
		sprintf(info, "\n<div><p style=\"margin-bottom:0\">%d événements au total dont : \n<ul style=\"margin-top:0\" >\n\t<li>%d événements uniques</li>\n\t<li>%d événements répétitifs</li>\n\t<li>%d événement à la journée</li>\n</ul><p></div>", nbU+nbJ+nbR, nbU,nbR,nbJ);
		strcat(html, info);
		//printf("%s", html);
		fprintf(htmlpage, html);
		fprintf(htmlpage,"</body>\n");
		fprintf(htmlpage,"</html>\n");
		printf("\n\nFICHIER HTML index.html CREE\n\n");
	}else{
		printf("Pas de traduction car données non valide");
	}

	fclose(htmlpage);
 	return 0;
 }
 
