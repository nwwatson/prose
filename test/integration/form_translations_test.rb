require "test_helper"

# Labels and submit buttons without explicit text come from the Active Record
# translations.
class FormTranslationsTest < ActionDispatch::IntegrationTest
  include LocaleHelper

  setup { spanish_site! }

  test "sign-in form labels" do
    get new_admin_session_path

    assert_select "label[for=email]", "Correo electrónico"
    assert_select "label[for=password]", "Contraseña"
  end

  test "implicit labels and submit buttons" do
    sign_in_as(:admin)

    get new_admin_category_path
    assert_select "label[for=category_name]", "Nombre"
    assert_select "input[type=submit][value=?]", "Crear categoría"

    get edit_admin_category_path(categories(:technology))
    assert_select "input[type=submit][value=?]", "Actualizar categoría"
  end

  test "validation errors" do
    sign_in_as(:admin)

    post admin_categories_path, params: { category: { name: "" } }

    assert_select "li", "Nombre no puede estar en blanco"
  end
end
