module AppConstants
  TITLE = "Examino"
  BY = 'Sij s.r.l.'

  RAILS_ROOT_APP =
  if Rails.env.production?
    '/webapp/code/prod/examino_multi'
  else
    '/home/ubuntu/webapp/code/prod/examino_multi'
#    '/webapp/code/prod/examino_multi'
  end

  REV = "R. #{Rails.version} - #{RUBY_VERSION} V. 0.0.5"
end
# 0.0.0
# rifatta per malfunzionamento tailwind
# 0.0.2
# analisi dati
# 0.0.3
# costante GRUPPO SNAI
# 0.0.4
# MULTIDB primo passo
