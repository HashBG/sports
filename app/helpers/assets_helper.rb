module AssetsHelper
  def coefficient_button(variable, bet_type, bet_result, modifier = nil)
    coefficient = "#{variable}['#{bet_type}']"
    coefficient << "[#{modifier}]" if modifier
    coefficient << "['#{bet_result}']"
    
    r = '<button type="button" class="btn btn-default btn-sm" ng-click="'

    if modifier
      r << "setBet(#{variable},'#{bet_type}', '#{bet_result}', #{modifier})\""
      r << " ng-disabled=\"disableSetBet(#{variable},'#{bet_type}', '#{bet_result}', #{modifier})\""
    else
      r << "setBet(#{variable},'#{bet_type}', '#{bet_result}')\""
      r << " ng-disabled=\"disableSetBet(#{variable},'#{bet_type}', '#{bet_result}')\""
    end
    
    r << ">{{ "
    r << coefficient
    r << " }}</button>"
    r
  end
end
