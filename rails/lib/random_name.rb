# frozen_string_literal: true

module RandomName
  def self.generate
    [
      Spicy::Proton.adjective(max: 7),
      Spicy::Proton.noun(max: 7),
      rand(10..99),
    ].compact.join('-')
  end
end
