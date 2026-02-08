Thanks for the submission. You’ve got the right overall approach: a cumulative “actors” build, a backfill that collapses stable periods into SCD ranges, and an incremental step to roll the SCD forward year-over-year. Below are the main strengths and the concrete issues to fix, plus suggested corrections.

What’s working well

Backfill logic: Using LAG + a running SUM to create a period “indicator” is a solid approach for grouping contiguous years. The grouping and min/max years per indicator are correct.
Cumulative “actors” build: The FULL OUTER JOIN between prior year and today’s activity gives you a row per actor every year, and correctly flips is_active based on whether an actor had films in that year.
Key issues to fix

DDL order: create types before tables that reference them
In actors_ddl.sql you create the actors table before the film_stats and quality_class types. In Postgres, referenced types must exist first. Fix the order:
CREATE TYPE quality_class
CREATE TYPE film_stats
CREATE TABLE actors
Incremental SCD: last_year_scd filter is too restrictive
You currently select only rows with start_date = 2020 AND end_date = 2020. That will exclude any period that started before 2020 and continued through 2020 (a very common case).
Fix: select the final 2020 slice for each actor by using end_date = 2020 (and current_year = 2020 if you want to be strict). Remove the start_date = 2020 filter.
Incremental SCD: changed_records join/filtering is wrong
You put the change predicate in the LEFT JOIN condition: LEFT JOIN last_year_scd ly ON ty.actorid = ly.actorid AND (ty.quality_class <> ly.quality_class OR ty.is_active <> ly.is_active) This will produce ly = NULL for unchanged rows and for new actors, but you then still UNNEST two records, creating bad/null rows and duplicates.
Fix: join on actorid normally, and put the change predicate in a WHERE clause. Use an INNER JOIN so only changed actors appear here.
Incremental SCD: indicator is missing and must be carried forward
actors_history_scd has an indicator column, and your backfill creates it. The incremental should:
Carry ly.indicator forward for unchanged rows.
For changed rows: emit two records:
Close the prior period with ly.indicator.
Open a new period with ly.indicator + 1.
For brand new actors in 2021, set indicator = 0 (first segment).
Your current incremental query does not output indicator, so it won’t be insertable into the table as defined.
Incremental SCD: include an INSERT or match the table schema explicitly
Your incremental script is a SELECT only. If the goal is to populate the 2021 rows, add: INSERT INTO actors_history_scd (actorid, actor, quality_class, is_active, indicator, start_date, end_date, current_year) … SELECT …
Also ensure your column list matches the table schema (including indicator and current_year).
Safer change-comparisons
Use IS DISTINCT FROM / IS NOT DISTINCT FROM to avoid null-related surprises in comparisons (even if you expect no nulls).
Minor/style issues
Alias casing ty vs tY is inconsistent; Postgres folds unquoted identifiers, but it’s better to be consistent.
Consider parameterizing years (prev_year, this_year) instead of hardcoding 2020/2021.
In actors_cumulative, consider adding ORDER BY inside ARRAY_AGG for deterministic film order.
Suggested corrected incremental approach (outline)

Fix last_year_scd SELECT actorid, actor, quality_class, is_active, indicator, start_date, end_date FROM actors_history_scd WHERE current_year = 2020 AND end_date = 2020

Keep historical_scd as-is but include indicator in the select list.

For changed rows, split into two CTEs to avoid the UNNEST complexity: changed_close_records: ly.* qualities, end at ty.current_year, indicator = ly.indicator changed_open_records: ty qualities, start & end at ty.current_year, indicator = ly.indicator + 1

For unchanged_records: carry ly.indicator and ly.start_date, set end_date = ty.current_year.

For new_records: set indicator = 0.

Insert: INSERT INTO actors_history_scd (actorid, actor, quality_class, is_active, indicator, start_date, end_date, current_year) SELECT …, 2021 AS current_year FROM ( historical_scd UNION ALL unchanged_records UNION ALL changed_close_records UNION ALL changed_open_records UNION ALL new_records )

If you prefer to keep your UNNEST pattern, you’ll need to:

Ensure changed_records only contains actors whose status actually changed (use INNER JOIN and WHERE).
After UNNEST, compute indicator with a CASE that increments only the “new” row (e.g., when start_date = end_date = ty.current_year), while carrying ly.indicator for the closing row.
What I need from you if you want me to finalize fixes

Confirm target database (I’m assuming Postgres based on ENUMs and composite types).
Confirm whether the incremental script should INSERT into actors_history_scd or just SELECT a result set.
Confirm desired indicator behavior for brand-new actors (defaulting to 0 is typical).
Let me know if you want years parameterized (e.g., pass prev_year/this_year variables) rather than hard-coded.
Optional: Provide a tiny sample dataset and the expected SCD output for 1–2 actors across 2020–2021 to validate the logic.
Overall assessment

The backfill and cumulative logic are close to correct.
The incremental SCD has critical issues that will drop history and/or create incorrect rows due to the restrictive last_year_scd filter and the changed_records join logic, and it omits the indicator required by your table.