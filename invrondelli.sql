with
Entradas as 
(select distinct(mprd_prod_codigo) as codprod, 
 sum(mprd_qtde) as entradas 
from movprodd14
where mprd_estentrada=1 
 and mprd_datamvto between '2014-01-01' and '2014-12-31' 
 and mprd_status<>'C'
 and mprd_unid_codigo='001' 
 and mprd_dcto_codigo<>'0' 
group by mprd_prod_codigo),

Saidas as 
(select distinct(mprd_prod_codigo) as codprod, 
 sum(mprd_qtde) as saidas 
from movprodd14
where mprd_estsaida=1 
 and mprd_datamvto between '2014-01-01' and '2014-12-31' 
 and mprd_status<>'C' 
 and mprd_unid_codigo='001' 
 and mprd_dcto_codigo<>'0'
group by mprd_prod_codigo),

Invinicio as
(select distinct(ifis_prod_codigo) as codprod,
 sum(ifis_estoque) as estoqueinicio
from invfisc1213
where ifis_unid_codigo='001'
group by ifis_prod_codigo),

Invfinal as
(select distinct(ifis_prod_codigo) as codprod,
 sum(ifis_estoque) as estoquefinal
from invfisc1214
where ifis_unid_codigo='001'
group by ifis_prod_codigo),

Sobras as 
(select distinct(mprd_prod_codigo) as codprod, 
 sum(mprd_qtde) as sobras 
from movprodd14
where mprd_estentrada=1 
 and mprd_datamvto between '2014-01-01' and '2014-12-31' 
 and mprd_status<>'C'
 and mprd_unid_codigo='001' 
 and mprd_dcto_tipo='ESE' 
group by mprd_prod_codigo),

Faltas as 
(select distinct(mprd_prod_codigo) as codprod, 
 sum(mprd_qtde) as faltas 
from movprodd14
where mprd_estsaida=1 
 and mprd_datamvto between '2014-01-01' and '2014-12-31' 
 and mprd_status<>'C' 
 and mprd_unid_codigo='001' 
 and mprd_dcto_tipo='EFE'
group by mprd_prod_codigo)

select 
 prod_codigo,
 prod_descricao,
 prod_complemento,
 prod_marca,
 case when Entradas.entradas is not null 
 then Entradas.entradas else 0.000
 end as entradas,
 
 case when Saidas.saidas is not null 
 then Saidas.saidas else 0.000
 end as saidas,
 
 case when Invinicio.estoqueinicio is not null
 then Invinicio.estoqueinicio else 0.000
 end as estoqueinicio,
 
 case when Invfinal.estoquefinal is not null
 then Invfinal.estoquefinal else 0.000
 end as estoquefinal,
 
 coalesce((Invinicio.estoqueinicio + Entradas.entradas) - Saidas.saidas,0.000) as estoquefinalcalc,
 
 case when ((Invinicio.estoqueinicio + Entradas.entradas) - Saidas.saidas) <> Invfinal.estoquefinal
 then 'SIM' else 'NAO'
 end as divergencia,
 
 case when prod_codigo NOT IN (select ifis_prod_codigo from invfisc1213 where ifis_unid_codigo='001')
 then 'NAO' else 'SIM'
 end as presencainicio,
 
 case when prod_codigo NOT IN (select ifis_prod_codigo from invfisc1214 where ifis_unid_codigo='001')
 then 'NAO' else 'SIM'
 end as presencafinal,
 
 case when Sobras.sobras is not null 
 then Sobras.sobras else 0.000
 end as sobras,
 
 case when Faltas.faltas is not null 
 then Faltas.faltas else 0.000
 end as faltas
 
from produtos
left join Entradas on (prod_codigo=Entradas.codprod)
left join Saidas on (prod_codigo=Saidas.codprod)
left join Invinicio on (prod_codigo=Invinicio.codprod)
left join Invfinal on (prod_codigo=Invfinal.codprod)
left join Sobras on (prod_codigo=Sobras.codprod)
left join Faltas on (prod_codigo=Faltas.codprod)
inner join produn on (prun_prod_codigo=prod_codigo and prun_unid_codigo='001')

group by 
prod_codigo,
prod_descricao,
prod_complemento,
prod_marca,
Entradas.entradas, 
Saidas.saidas,
Invinicio.estoqueinicio,
Invfinal.estoquefinal,
Sobras.sobras,
Faltas.faltas
order by prod_codigo
