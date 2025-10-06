require 'faker'

# USUÁRIOS
puts "\nCriando usuários"

100.times do |i|
  email = "user#{i + 1}@timeregister.com"

  User.find_or_create_by!(email: email) do |user|
    user.name = Faker::Name.name
  end

  print "." if (i + 1) % 10 == 0
end

# REGISTROS DE PONTO
puts "\nCriando registros de ponto"

created_count = 0

User.find_each do |user|
  # Gerar 20 dias de trabalho nos últimos 90 dias
  20.times do |day_index|
    # Distribuir registros nos últimos 90 dias
    days_ago = rand(1..90)
    date = days_ago.days.ago.to_date

    # Pular finais de semana
    date += 1.day while date.saturday? || date.sunday?

    # Horários base (com variações)
    morning_in = date.to_time + 8.hours + rand(0..60).minutes
    lunch_out = date.to_time + 12.hours + rand(0..30).minutes
    lunch_in = lunch_out + 1.hour + rand(0..15).minutes
    evening_out = date.to_time + 18.hours + rand(-30..30).minutes

    # 90% dos casos: dia completo com 2 registros (manhã e tarde)
    # 10% dos casos: apenas 1 registro (dia completo sem pausa)
    if rand(100) < 90
      # Período da manhã
      unless Clocking.exists?(user: user, clock_in: morning_in)
        Clocking.create!(
          user: user,
          clock_in: morning_in,
          clock_out: lunch_out
        )
        created_count += 1
      end

      # Período da tarde
      unless Clocking.exists?(user: user, clock_in: lunch_in)
        Clocking.create!(
          user: user,
          clock_in: lunch_in,
          clock_out: evening_out
        )
        created_count += 1
      end
    else
      # Dia completo sem pausa registrada
      unless Clocking.exists?(user: user, clock_in: morning_in)
        Clocking.create!(
          user: user,
          clock_in: morning_in,
          clock_out: evening_out
        )
        created_count += 1
      end
    end
  end
end

puts "Registros criados nesta execução: #{created_count}"
puts "Total de registros no sistema: #{Clocking.count}"

# RESUMO
puts "Seed concluído com sucesso!"
puts "\nResumo:"
puts "• Usuários: #{User.count}"
puts "• Registros de ponto: #{Clocking.count}"
puts "• Média por usuário: #{(Clocking.count.to_f / User.count).round(2)}"
