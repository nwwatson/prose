module LocaleHelper
  def spanish_site!
    SiteSetting.current.update!(locale: "es")
  end
end
