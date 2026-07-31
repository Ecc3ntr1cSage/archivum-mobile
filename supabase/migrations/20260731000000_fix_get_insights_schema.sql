create or replace function public.get_insights()
returns json
language plpgsql
security definer
set search_path = public
as $function$
declare
  _uid uuid := auth.uid();
  _result json;
  _note_count int;
  _index_count int;
  _index_item_count int;
  _total_prayers int;
  _total_days int;
  _avg_daily numeric;
  _streak int;
  _account_count int;
  _tag_count int;
  _note_tags json;
  _account_methods json;
  _sso_providers json;
  _tag_features json;
  _completion_rate numeric;
begin
  select count(*) into _note_count
  from public.notes
  where user_id = _uid;

  select count(*) into _index_count
  from public.indexes
  where user_id = _uid;

  select count(*) into _index_item_count
  from public.index_items ii
  join public.indexes i on ii.index_id = i.id
  where i.user_id = _uid;

  select
    coalesce(sum(
      (case when fajr then 1 else 0 end) +
      (case when dhuhr then 1 else 0 end) +
      (case when asr then 1 else 0 end) +
      (case when maghrib then 1 else 0 end) +
      (case when isha then 1 else 0 end)
    ), 0),
    count(*)
  into _total_prayers, _total_days
  from public.prayers
  where user_id = _uid;

  if _total_days > 0 then
    _avg_daily := round(_total_prayers::numeric / _total_days, 1);
    _completion_rate := round((_total_prayers::numeric / (_total_days * 5)) * 100, 0);
  else
    _avg_daily := 0;
    _completion_rate := 0;
  end if;

  with streaks as (
    select
      date,
      (fajr and dhuhr and asr and maghrib and isha) as all_five,
      date - (row_number() over (
        partition by (fajr and dhuhr and asr and maghrib and isha)
        order by date
      ))::int as grp
    from public.prayers
    where user_id = _uid
  )
  select coalesce(max(cnt), 0) into _streak
  from (
    select grp, count(*) as cnt
    from streaks
    where all_five = true
    group by grp
  ) s;

  select count(*) into _account_count
  from public.credentials
  where user_id = _uid;

  select count(*) into _tag_count
  from public.tags
  where user_id = _uid;

  select coalesce(json_agg(row_to_json(t)), '[]'::json) into _note_tags
  from (
    select coalesce(tag, 'untagged') as tag, count(*) as count
    from public.notes
    where user_id = _uid
    group by tag
    order by count desc
  ) t;

  select coalesce(json_agg(row_to_json(t)), '[]'::json) into _account_methods
  from (
    select coalesce(method, 'unknown') as method, count(*) as count
    from public.credentials
    where user_id = _uid
    group by method
    order by count desc
  ) t;

  select coalesce(json_agg(row_to_json(t)), '[]'::json) into _sso_providers
  from (
    select coalesce(provider, 'unknown') as provider, count(*) as count
    from public.credentials
    where user_id = _uid
      and lower(coalesce(method, '')) = 'sso'
    group by provider
    order by count desc
  ) t;

  select coalesce(json_agg(row_to_json(t)), '[]'::json) into _tag_features
  from (
    select feature, count(*) as count
    from public.tags
    where user_id = _uid
    group by feature
    order by count desc
  ) t;

  _result := json_build_object(
    'total_notes', _note_count,
    'total_content', _note_count,
    'total_indexes', _index_count,
    'total_index_items', _index_item_count,
    'total_prayers', _total_prayers,
    'total_prayer_days', _total_days,
    'avg_daily_prayers', _avg_daily,
    'longest_streak', _streak,
    'completion_rate', _completion_rate,
    'total_accounts', _account_count,
    'total_tags', _tag_count,
    'note_tags', _note_tags,
    'account_methods', _account_methods,
    'sso_providers', _sso_providers,
    'tag_features', _tag_features
  );

  return _result;
end;
$function$;
