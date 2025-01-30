{{
    config(
        unique_key = [
            'agent_user_name'
        ]
    )
}}

WITH raw_data AS (

    SELECT
        "agentusername"     AS agent_user_name,
        "agentnpn"          AS agent_npn,
        "agent_email"       AS agent_email,
        "agentfirstname"    AS agent_first_name,
        "agentlastname"     AS agent_last_name,
        "ingestiondate"     AS emitted_at
      FROM {{ source('landing', 'agent') }}
     WHERE
        agentusername <> ''
        AND agentnpn <> ''
    {% if var("emitted_at") %}
       {{ print("Running with emitted_at: " ~ var("emitted_at")) }}
       AND ingestiondate = '{{ var("emitted_at") }}'
    {% endif %}

), normalized_data AS (

    SELECT *
        , ROW_NUMBER() OVER (
            PARTITION BY
                agent_user_name
            ORDER BY
                emitted_at desc
        ) AS row_index
        , '{{ var("run_started_at") }}' AS normalized_at
    FROM raw_data

), deduped_data AS (

    SELECT *
    FROM normalized_data
    WHERE row_index = 1

), final AS (

    SELECT
        agent_user_name,
        agent_npn,
        agent_email,
        agent_first_name,
        agent_last_name,
        normalized_at
    FROM deduped_data

)

SELECT * FROM final
