module AssetsHelper
  def coefficient_button(variable, bet_type, bet_result, modifier = nil)
    #coefficient = "#{variable}['#{bet_type}']"
    #coefficient << "[#{modifier}]" if modifier
    #coefficient << "['#{bet_result}']"
    #coefficient << "[oddsRepresentation]"
    
    r = '<button type="button" class="btn btn-default btn-sm" ng-click="'

    r << "setBet(#{variable},'#{bet_type}', '#{bet_result}', #{modifier || 'null'})\""
    r << " ng-disabled=\"disableSetBet(#{variable},'#{bet_type}', '#{bet_result}', #{modifier || 'null'})\""
    
    r << ">{{ showCoefficient(#{variable},'#{bet_type}', '#{bet_result}', #{modifier || 'null'}) }}</button>"
    #r << "> {{"
    #r << coefficient
    #r << " }}</button>"
    r
  end
end
