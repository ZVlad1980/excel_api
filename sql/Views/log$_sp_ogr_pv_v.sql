create or replace view log$_sp_ogr_pv_v as
  select o.id, 
         o.action, 
         o.nom_vkl, 
         o.nom_ips, 
         o.kod_ogr_pv, 
         o.nach_deistv,
         o.okon_deistv,
         o.primech, 
         o.ssylka_fl, 
         o.kod_insz, 
         o.ssylka_td, 
         o.rid_td, 
         o.status, 
         o.inserted_at,
         o.created_at, 
         o.created_by,
         case o.id
           when max(id)
                  keep(dense_rank last order by o.created_at)
                  over(partition by o.nom_vkl, o.nom_ips, o.rid_td) then
             o.id
         end last_id
  from   log$_sp_ogr_pv o
