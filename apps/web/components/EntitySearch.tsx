"use client";

import { useMemo, useState } from "react";
import { normalize, searchEntities, type SearchableEntity } from "@/lib/search";
import { CorrectionForm } from "@/components/CorrectionForm";

function Row({ e }: { e: SearchableEntity }) {
  return (
    <a className="ent-row" href={`/entreprise/${e.slug}`}>
      {e.grade ? (
        <span className={`grade sm grade-${e.grade}`}>{e.grade}</span>
      ) : (
        <span className="grade sm grade-none" title="Pas encore notée">—</span>
      )}
      <span className="ent-main">
        <span className="ent-name">{e.name}</span>
        {e.group && <small className="muted">{e.group}</small>}
      </span>
      <span className="chev" aria-hidden="true">›</span>
    </a>
  );
}

/**
 * Recherche instantanée sur la liste complète (aucune requête réseau).
 *
 * Deux partis pris :
 *  - on cherche aussi par **groupe propriétaire** : taper « Unilever » remonte
 *    ses marques, parce que c'est là que va l'argent ;
 *  - une recherche sans résultat ne se termine pas par un cul-de-sac. La base
 *    ne couvre pas encore tout, et l'absence d'une marque n'est **pas** un
 *    jugement sur elle : on le dit, et on propose de la signaler.
 */
export function EntitySearch({
  entities,
  children,
}: {
  entities: SearchableEntity[];
  children: React.ReactNode;
}) {
  const [query, setQuery] = useState("");
  const results = useMemo(() => searchEntities(entities, query), [entities, query]);
  // Une requête qui ne contient que de la ponctuation ne déclenche pas la recherche.
  const searching = normalize(query).length > 0;

  return (
    <>
      <div className="search-box">
        <span className="search-icon" aria-hidden="true">⌕</span>
        <input
          type="search"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder={`Rechercher parmi ${entities.length} entités — marque ou groupe`}
          aria-label="Rechercher une marque ou un groupe"
          autoComplete="off"
        />
        {query && (
          <button type="button" className="search-clear" onClick={() => setQuery("")} aria-label="Effacer">
            ×
          </button>
        )}
      </div>

      {!searching ? (
        children
      ) : results.length > 0 ? (
        <section>
          <h2 className="list-title">
            Résultats <span className="muted">{results.length}</span>
          </h2>
          <div className="ent-list">
            {results.map((e) => (
              <Row key={e.slug} e={e} />
            ))}
          </div>
        </section>
      ) : (
        <section>
          <div className="panel">
            <strong>Aucune entité ne correspond à « {query.trim()} ».</strong>
            <p className="muted small" style={{ marginBottom: 0, lineHeight: 1.5 }}>
              La base ne couvre pas encore tout : l'absence d'une marque n'est{" "}
              <strong>pas un jugement</strong> sur elle, seulement une donnée qui
              manque. Signalez-la et elle entrera dans la file de curation.
            </p>
          </div>
          <div style={{ marginTop: 12 }}>
            <CorrectionForm entitySlug={query.trim().slice(0, 120)} />
          </div>
        </section>
      )}
    </>
  );
}
