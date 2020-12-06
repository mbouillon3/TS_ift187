/*############################################################################
 un script SQL pour les invariants requis – vues, routines et déclencheurs (triggers)
 ############################################################################*/

/* ####################################################################
 Liste des modifications a faire dans le doc

   - Ajouter les predicats qui justifient la presence des triggers
   - Faire la mise en page du doc
   - Maybe mettre des views, idk on a pas fait les requetes encore alors je sais pas quoi mettre mais on va surement en avoir une couple

 ####################################################################*/



CREATE OR REPLACE FUNCTION validation_doublages_films_participations()
RETURNS TRIGGER AS
    $$
    BEGIN

        -- Verification du doubleur
        if (not exists(
                select *
                from participations_films df
                where df.id_film = new.id_film and
                      df.id_artisan = new.artisan_doubleur and
                      df.id_emploi = (select id_emploi from emplois where emploi = 'Doubleur')

            )

            -- Verification de l'artisan double
            or not exists(
                select *
                from participations_films df
                where df.id_film = new.id_film and
                      df.id_artisan = new.artisan_double and
                      df.id_emploi = (select id_emploi from emplois where emploi = 'Acteur')
            )) then
            raise notice 'Erreur dans la selection des artisans. Veuillez verifier qu''ils sont bien dans la table participation_films avec les bon emplois!';
            return null;

        else return new;
        end if;

    END
    $$
LANGUAGE plpgsql;

create trigger insertions_doublages_films_participations
    before insert
    on doublages_films
    for each row
    execute procedure validation_doublages_films_participations();




CREATE OR REPLACE FUNCTION validation_doublages_films_duplicata()
RETURNS TRIGGER AS
    $$
    BEGIN
        if (new.artisan_doubleur = new.artisan_double) then
            raise notice 'L''artisan doubleur ne peut pas etre l''artisan double!';
            return null;

        else return new;
        end if;

    END
    $$
LANGUAGE plpgsql;

create trigger insertions_doublages_films_duplicata
    before insert
    on doublages_films
    for each row
    execute procedure validation_doublages_films_duplicata();



-- TRIGGER PARTICIPATION_FILMS
CREATE OR REPLACE FUNCTION validation_participations_films_date_naissance()
RETURNS TRIGGER AS
    $$
    BEGIN
        if (
            (select extract(year from date_naissance)
            from date_naissances
            where id_artisan = new.id_artisan)
            >
            (select annee_de_parution
            from films
            where id_film = new.id_film))
            then
            raise notice 'L''artisan n''etait pas ne a la sortie du film!';
            return null;

        else return new;
        end if;

    END
    $$
LANGUAGE plpgsql;

create trigger insertions_participations_films
    before insert
    on participations_films
    for each row
    execute procedure validation_participations_films_date_naissance();


-- TRIGGER REMISE_PRIX_FILMS
create or replace function validation_remises_prix_films_annee()
returns trigger as
    $$
        begin
            if (
                new.annee
                <
                (select annee_de_parution
                from films
                where id_film = new.id_film)
                ) then
                raise notice 'Le film n''etait pas sorti a l''annee de la remise de ce prix!';
                return null;

            else return new;
            end if;
        end
    $$
language plpgsql;

create trigger insertions_remises_prix_films
    before insert
    on remises_prix_films
    for each row
    execute procedure validation_remises_prix_films_annee();



-- TRIGGER REMISE_PRIX_ARTISANS
create or replace function validation_remises_prix_artisans_participation()
returns trigger as
    $$
        begin
            if (
                not exists(
                    select *
                    from participations_films pf
                    where pf.id_artisan = new.id_artisan)
                ) then
                raise notice 'L''artisan ne fait pas parti de ce film!';
                return null;

            else return new;
            end if;
        end
    $$
language plpgsql;

create trigger insertions_remises_prix_artisans_participation
    before insert
    on remises_prix_artisans
    for each row
    execute procedure validation_remises_prix_artisans_participation();





-- TRIGGER REMISE_PRIX_ARTISANS
create or replace function validation_remises_prix_artisans_annee()
returns trigger as
    $$
        begin
            if (
                new.annee
                <
                (select annee_de_parution
                from films
                where id_film = new.id_film)
                ) then
                raise notice 'Le film n''etait pas sorti a l''annee de la remise de ce prix!';
                return null;

            else return new;
            end if;
        end
    $$
language plpgsql;

create trigger insertions_remises_prix_artisans_annee
    before insert
    on remises_prix_artisans
    for each row
    execute procedure validation_remises_prix_artisans_annee();



-- TRIGGER RECETTES POUR LE PAYS
create or replace function validation_recettes_pays()
returns trigger as
    $$
        begin
            if (not exists(
                select *
                from pays_presentes pp
                where pp.id_film = new.id_film and
                      pp.id_pays = new.id_pays
                )) then
                raise notice 'Le film n''a pas ete presente dans ce pays!';
                return null;

            else return new;
            end if;
        end
    $$
language plpgsql;

create trigger insertions_recettes_pays
    before insert
    on recettes
    for each row
    execute procedure validation_recettes_pays();




-- TRIGGER RECETTES POUR L'ANNEE
create or replace function validation_recettes_annee()
returns trigger as
    $$
        begin
            if (
                new.annee
                <
                (select annee_de_parution
                from films
                where id_film = new.id_film)
                ) then
                raise notice 'Le film n''etait pas sorti a l''annee entree!';
                return null;

            else return new;
            end if;
        end
    $$
language plpgsql;

create trigger insertions_recettes_annee
    before insert
    on recettes
    for each row
    execute procedure validation_recettes_annee();