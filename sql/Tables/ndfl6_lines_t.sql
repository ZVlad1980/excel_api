create table ndfl6_lines_t(
  line_id            int generated as identity primary key,
  header_id          int,
  tax_rate           number not null,
  nom_vkl            number(10,0) not null, 
  nom_ips            number(10,0) not null, 
  gf_person          number,
  det_charge_type    varchar2(7), 
  pen_scheme         varchar2(3), 
  revenue_amount     number, 
  benefit            number, 
  tax_retained       number, 
  tax_calc           number,
  tax_returned_prev  number,
  tax_returned_curr  number, 
  tax_corr_83        number,
  tax_corr_prev      number,
  tax_corr_curr      number,
  constraint ndfl6_line_hdr_fk foreign key (header_id)
    references ndfl6_headers_t(header_id)
)
/
create index ndfl6_lines_hdr_idx on ndfl6_lines_t(header_id)
/