export const ESTADOS_BRASIL: Record<string, string> = {
  ac: 'Acre',
  al: 'Alagoas',
  ap: 'Amapá',
  am: 'Amazonas',
  ba: 'Bahia',
  ce: 'Ceará',
  df: 'Distrito Federal',
  es: 'Espírito Santo',
  go: 'Goiás',
  ma: 'Maranhão',
  mt: 'Mato Grosso',
  ms: 'Mato Grosso do Sul',
  mg: 'Minas Gerais',
  pa: 'Pará',
  pb: 'Paraíba',
  pr: 'Paraná',
  pe: 'Pernambuco',
  pi: 'Piauí',
  rj: 'Rio de Janeiro',
  rn: 'Rio Grande do Norte',
  rs: 'Rio Grande do Sul',
  ro: 'Rondônia',
  rr: 'Roraima',
  sc: 'Santa Catarina',
  sp: 'São Paulo',
  se: 'Sergipe',
  to: 'Tocantins'
};

export const ESTADOS_LISTA = Object.entries(ESTADOS_BRASIL).map(([sigla, nome]) => ({
  sigla: sigla.toUpperCase(),
  siglaLower: sigla,
  nome,
  nomeCompleto: `${nome} (${sigla.toUpperCase()})`
})).sort((a, b) => a.nome.localeCompare(b.nome));
