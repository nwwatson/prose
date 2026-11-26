# Translated labels for Stimulus controllers that several views mount, so the
# value attributes are written once.
module StimulusLabelsHelper
  def autosave_labels
    tag.attributes(data: {
      autosave_unsaved_label_value: t("layouts.editor.autosave.unsaved"),
      autosave_saving_label_value: t("layouts.editor.autosave.saving"),
      autosave_saved_label_value: t("layouts.editor.autosave.saved"),
      autosave_error_label_value: t("layouts.editor.autosave.error")
    })
  end

  def code_highlight_labels
    tag.attributes(data: {
      code_highlight_copy_label_value: t("shared.copy"),
      code_highlight_copied_label_value: t("shared.copied"),
      code_highlight_failed_label_value: t("shared.copy_failed")
    })
  end
end
