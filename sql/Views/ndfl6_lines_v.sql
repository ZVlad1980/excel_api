create or replace view ndfl6_lines_v as
  select d.tax_rate,
         d.nom_vkl,
         d.nom_ips,
         d.gf_person,
         d.det_charge_type,
         d.pen_scheme,
         --����� ������ � ������ ������������� �������� ���������� �������
         sum(case
               when d.charge_type = 'REVENUE' and
                    nvl(d.is_corr_curr_year, 'Y') = 'Y' then
                 d.summa
             end
         )                                                           revenue_amount,
         --����� ���������������� ������ �� �����/��-����������!
         sum(case d.charge_type when 'BENEFIT' then d.summa end)     benefit,
         --���������� ����� ������
         sum(case d.charge_type when 'TAX'     then d.summa end)     tax_retained,
         --����������� ����� ������ (����� ������� ������ ��� ������������!)
         sum(case 
               when d.tax_rate = 30 and 
                    d.charge_type = 'REVENUE' then
                 round(d.summa * .3, 0) 
             end
         )                                                           tax_calc,
         --����� ������������� ������ �� ������� ������� �� �������
         sum(case d.charge_type when 'TAX_CORR' then d.summa end)    tax_corr_83,
         --����� ������������� ������ �� ���������� �������
         sum(case
               when d.is_tax_returned = 'Y' and 
                    d.is_corr_curr_year = 'N' then
                 d.summa
             end
         )                                                           tax_returned_prev,
         --����� ������������� ������ �� ������� ������
         sum(case
               when d.is_tax_returned = 'Y' and 
                    d.is_corr_curr_year = 'Y' then
                 d.summa
             end
         )                                                           tax_returned_curr,
         --����� ������������� (� �.�. �������������) ������ �� ���������� �������
         sum(case
               when d.charge_type = 'TAX'  and
                    d.is_corr_curr_year = 'N' then
                 d.summa
             end
         )                                                           tax_corr_prev,
         --����� ������������� (� �.�. �������������) ������ �� ������� ������
         sum(case
               when d.charge_type = 'TAX' and 
                    d.is_corr_curr_year = 'Y' then
                 d.summa
             end
         )                                                           tax_corr_curr
  from   ndfl_dv_sr_lspv_v d
  group  by 
    d.tax_rate,
    d.nom_vkl,
    d.nom_ips,
    d.gf_person,
    d.det_charge_type,
    d.pen_scheme
/
