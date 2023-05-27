%{
	#include <stdio.h>
	#include <string.h>
	#include "y.tab.h"

	extern int yylval;
	extern int tab1[1000][5];
	extern char buffer[100000];
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

	// |(0)Type - (1)Complementaire - (2)REFERENCE - (3)DEBUTBUFF - (4)FINBUFF|
	int indice = -1; //Trave la ligne ou ecrire
	int dernierEvt = -1; //indice dernier evennement
	
%}
%start LIGNEOK
%start DATEUOK
%start DATEROK
%start DATEJOK
%start NBOK
%start JOUROK
%start ALARM
%start TEXTOK
%%
BEGIN:VCALENDAR	{printf("Début calendrier\n"); return DEBCAL;}
END:VCALENDAR	{printf("Fin calendrier\n");return FINCAL;}
BEGIN:VEVENT	{printf("Début événement\n"); BEGIN LIGNEOK;return DEBEVT;}
END:VEVENT	{printf("Fin événement\n");return FINEVT;}
<LIGNEOK>DTSTART:	{printf("intro heure début evt unique\n"); 
					indice++;
					dernierEvt=indice;
					tab1[indice][0]=EVT;
					tab1[indice][1]=UNIQ;
					tab1[indice][2]=-1;
					tab1[indice][3]=-1;
					tab1[indice][4]=-1;
					BEGIN DATEUOK;
					return IDEBEVTU;
}

<LIGNEOK>DTEND:		{printf("intro heure fin evt unique\n"); BEGIN DATEUOK;return IFINEVTU;}
<LIGNEOK>DESCRIPTION:	{ printf("intro description\n"); BEGIN TEXTOK; return IDESCR;}
			
<LIGNEOK>LOCATION:	{printf("intro lieu\n"); BEGIN TEXTOK;return ILIEU;}
<LIGNEOK>SUMMARY:	{printf("intro titre\n"); BEGIN TEXTOK;return ITITRE;}

<LIGNEOK>BEGIN:VALARM	{printf("Début alarme\n"); BEGIN ALARM;return DEBAL;}
<ALARM>END:VALARM	{printf("Fin alarme\n"); BEGIN LIGNEOK;return FINAL;}
<ALARM>TRIGGER:	{printf("intro position alarme\n");return TRIGGER;}
<LIGNEOK>RRULE:		{printf("intro règle répétition\n");return RRULE;}
<LIGNEOK>FREQ=		{printf("intro fréquence\n");return FREQ;}
<LIGNEOK>COUNT=		{printf("intro compteur\n"); BEGIN NBOK;return COUNT;}
<LIGNEOK>BYDAY=		{
					//printf("intro liste jours\n"); 
					BEGIN JOUROK;return BYDAY;}
<LIGNEOK>UNTIL=		{
					//printf("intro limite\n");
					BEGIN DATEUOK;return UNTIL;}
<LIGNEOK>WKST=SU	{
						//printf("changement de semaine\n");
						return WKST;}
						
<LIGNEOK>DAILY|WEEKLY|MONTHLY|YEARLY	{
						//printf("frequence : %s\n", yytext);
						indice++;
						tab1[indice][0]=FRE;
						tab1[indice][1]=PER;
						tab1[indice][2]=dernierEvt;
						tab1[indice][3]=strlen(buffer);
						tab1[indice][4]=yyleng;
						strcat(buffer,yytext);
						yylval = indice;
						return VALFREQ;}

<LIGNEOK>;		{printf("séparateur options\n");return PV;}
<LIGNEOK>DTSTART;TZID=[a-zA-Z/]+:	{
					//printf("intro heure début evt répétitif\n"); 
					indice++;
					dernierEvt=indice;
					tab1[indice][0]=EVT;
					tab1[indice][1]=REPET;
					tab1[indice][2]=-1;
					tab1[indice][3]=-1;
					tab1[indice][4]=-1;
					BEGIN DATEROK;
					return DEBEVTR;}

<LIGNEOK>DTEND;TZID=[a-zA-Z/]+:		{printf("intro heure fin evt répétitif\n"); 
						BEGIN DATEROK;return FINEVTR;}
<LIGNEOK>DTSTART;VALUE=DATE:	{
						//printf("intro heure début evt journée\n");
						indice++;
						dernierEvt=indice;
						tab1[indice][0]=EVT;
						tab1[indice][1]=JOURN;
						tab1[indice][2]=-1;
						tab1[indice][3]=-1;
						tab1[indice][4]=-1;
						BEGIN DATEJOK;
						return DEBEVTJ;
						}
<LIGNEOK>DTEND;VALUE=DATE:		{printf("intro heure fin evt journée\n"); 
						BEGIN DATEJOK;return FINEVTJ;}
<ALARM>"-P"[0-9]+DT[0-9]+H[0-9]+M[0-9]+S	{printf("position alarme : %s\n", yytext);
						indice++;
						tab1[indice][0]=ALAR;
						tab1[indice][1]=-1;
						tab1[indice][2]=dernierEvt;
						tab1[indice][3]=strlen(buffer);
						tab1[indice][4]=yyleng;
						strcat(buffer,yytext);
						yylval = indice;
						return POSAL;
						}
<DATEJOK>[0-9]{8}	{printf("date evt journée : %s\n", yytext); 
		indice++;
		tab1[indice][0]=DAT;
		tab1[indice][2]=dernierEvt;
		tab1[indice][3]=strlen(buffer);
		tab1[indice][4]=yyleng;
		strcat(buffer,yytext);
		yylval = indice;
		BEGIN LIGNEOK;
		return DATEVTJ;}

<NBOK>[0-9]+		{printf("nombre entier : %s\n", yytext); 
					indice++;
					tab1[indice][0]=FRE;
					tab1[indice][1]=CPT;
					tab1[indice][2]=dernierEvt;
					tab1[indice][3]=strlen(buffer);
					tab1[indice][4]=yyleng;
					strcat(buffer,yytext);
					yylval = indice;
					BEGIN LIGNEOK;
					return NOMBRE;}

<DATEROK>[0-9]{8}T[0-9]{6}		{printf("date et heure evt répétitif : %s\n", yytext); 
						indice++;
						tab1[indice][0]=DAT;
						tab1[indice][2]=dernierEvt;
						tab1[indice][3]=strlen(buffer);
						tab1[indice][4]=yyleng;
						strcat(buffer,yytext);
						yylval = indice;
						BEGIN LIGNEOK;
						return DATEVTR;}

<DATEUOK>[0-9]{8}T[0-9]{6}Z		{
	printf("date et heure evt unique : %s\n", yytext);
	indice++;
	tab1[indice][0]=DAT;
	tab1[indice][2]=dernierEvt;
	tab1[indice][3]=strlen(buffer);
	tab1[indice][4]=yyleng;
	strcat(buffer,yytext);
	yylval = indice;
	BEGIN LIGNEOK;
	return DATEVTU;
}
<JOUROK>(SU|MO|TU|WE|TH|FR|SA)(,(SU|MO|TU|WE|TH|FR|SA)){0,6}	{
						printf("liste jours : %s\n", yytext); 
						indice++;
						tab1[indice][0]=FRE;
						tab1[indice][1]=LJ;
						tab1[indice][2]=dernierEvt;
						tab1[indice][3]=strlen(buffer);
						tab1[indice][4]=yyleng;
						strcat(buffer,yytext);
						yylval = indice;
						BEGIN LIGNEOK;
						return LISTJ;
						}

<TEXTOK>[^:\n]*$	{printf("Lieu, description ou titre : %s\n",yytext); 
			indice++;
			yytext[yyleng-1] = '\0';
			tab1[indice][0]=TXT;
			tab1[indice][2]=dernierEvt;
			tab1[indice][3]=strlen(buffer);
			tab1[indice][4]=yyleng-1;
			strcat(buffer,yytext);
			yylval = indice;
			BEGIN LIGNEOK;
			return TEXTE;}
.|\n ;
%%



int yywrap(void) {
	printf("FINI");
	printf("\tnom\ttype\tcible\tdeb\tfin\n");
	yylval = indice;
	for(int i =0;i<=indice;i++)
	{
		printf("\t%d\t%d\t%d\t%d\t%d\n",
		tab1[i][0],tab1[i][1],tab1[i][2],tab1[i][3],tab1[i][4]);
	}
	printf("\nBUFFER(%d) = %s",(int)strlen(buffer),buffer);
	return 1;
}

