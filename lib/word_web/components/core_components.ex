defmodule WordWeb.CoreComponents do
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  slot :inner_block, required: true

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      class="relative z-50 hidden"
    >
      <div id={"#{@id}-bg"} class="fixed inset-0 transition-opacity bg-zinc-50/90" aria-hidden="true" />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex items-center justify-center min-h-full">
          <div class="w-full max-w-3xl p-4 sm:p-6 lg:py-8">
            <.focus_wrap
              id={"#{@id}-container"}
              phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
              phx-key="escape"
              phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
              class="relative hidden transition bg-white shadow-lg shadow-zinc-700/10 ring-zinc-700/10 rounded-2xl p-14 ring-1"
            >
              <div class="absolute top-6 right-5">
                <button
                  phx-click={JS.exec("data-cancel", to: "##{@id}")}
                  type="button"
                  class="flex-none p-3 -m-3 opacity-20 hover:opacity-40"
                  aria-label="close"
                >
                  <.icon name="hero-x-mark-solid" class="w-5 h-5" />
                </button>
              </div>
              <div id={"#{@id}-content"}>
                <%= render_slot(@inner_block) %>
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class={[
        "fixed top-2 right-2 mr-2 w-80 sm:w-96 z-50 rounded-lg p-3 ring-1",
        @kind == :info && "bg-emerald-50 text-emerald-800 ring-emerald-500 fill-cyan-900",
        @kind == :error && "bg-rose-50 text-rose-900 shadow-md ring-rose-500 fill-rose-900"
      ]}
      {@rest}
    >
      <p :if={@title} class="flex items-center gap-1.5 text-sm font-semibold leading-6">
        <.icon :if={@kind == :info} name="hero-information-circle-mini" class="w-4 h-4" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle-mini" class="w-4 h-4" />
        <%= @title %>
      </p>
      <p class="mt-2 text-sm leading-5"><%= msg %></p>
      <button type="button" class="absolute p-2 group top-1 right-1" aria-label="close">
        <.icon name="hero-x-mark-solid" class="w-5 h-5 opacity-40 group-hover:opacity-70" />
      </button>
    </div>
    """
  end

  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id}>
      <.flash kind={:info} title="Success!" flash={@flash} />
      <.flash kind={:error} title="Error!" flash={@flash} />
      <.flash
        id="client-error"
        kind={:error}
        title="We can't find the internet"
        phx-disconnected={show(".phx-client-error #client-error")}
        phx-connected={hide("#client-error")}
        hidden
      >
        <%= "Attempting to reconnect" %>
        <.icon name="hero-arrow-path" class="w-3 h-3 ml-1 animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title="Something went wrong!"
        phx-disconnected={show(".phx-server-error #server-error")}
        phx-connected={hide("#server-error")}
        hidden
      >
        <%= "Hang in there while we get back on track" %>
        <.icon name="hero-arrow-path" class="w-3 h-3 ml-1 animate-spin" />
      </.flash>
    </div>
    """
  end

  attr :for, :any, required: true, doc: "the datastructure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target multipart),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class="mt-10 space-y-8 bg-white">
        <%= render_slot(@inner_block, f) %>
        <div :for={action <- @actions} class="flex items-center justify-between gap-6 mt-2">
          <%= render_slot(action, f) %>
        </div>
      </div>
    </.form>
    """
  end

  attr(:type, :string, default: nil)
  attr(:class, :string, default: nil)

  attr(:variant, :string,
    values: ~w(default secondary destructive outline ghost link),
    default: "default",
    doc: "the button variant style"
  )

  attr(:size, :string, values: ~w(default sm lg icon), default: "default")
  attr(:rest, :global, include: ~w(disabled form name value))

  slot(:inner_block, required: true)

  def button(assigns) do
    assigns = assign(assigns, :variant_class, variant(assigns))

    ~H"""
    <button
      type={@type}
      class={[
        "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium transition-colors disabled:pointer-events-none disabled:opacity-50",
        @variant_class,
        @class,
        ring_classes()
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  @variants %{
    variant: %{
      "default" => "bg-zinc-600 text-zinc-50 shadow hover:bg-zinc-600/90",
      "destructive" => "bg-rose-400 text-zinc-50 shadow-sm hover:bg-rose-400/90",
      "outline" =>
        "border border-zinc-300 bg-zinc-50 shadow-sm hover:bg-zinc-200 hover:bg-zinc-300",
      "secondary" => "bg-zinc-300 text-zinc-800 shadow-sm hover:bg-zinc-300/80",
      "ghost" => "hover:bg-200 hover:bg-zinc-800",
      "link" => "text-zinc-600 underline-offset-4 hover:underline"
    },
    size: %{
      "default" => "h-9 px-4 py-2",
      "sm" => "h-8 rounded-md px-3 text-xs",
      "lg" => "h-10 rounded-md px-8",
      "icon" => "h-9 w-9"
    }
  }

  @default_variants %{
    variant: "default",
    size: "default"
  }

  defp variant(props) do
    variants = Map.take(props, ~w(variant size)a)
    variants = Map.merge(@default_variants, variants)

    Enum.map_join(variants, " ", fn {key, value} -> @variants[key][value] end)
  end

  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file hidden month number password
               range radio search select tel text textarea time url week radiogroup)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  slot :inner_block

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, field.errors)
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div phx-feedback-for={@name}>
      <label class="flex items-center gap-4 text-sm leading-6 text-zinc-600">
        <input type="hidden" name={@name} value="false" />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class={["rounded text-zinc-900", ring_classes(@errors)]}
          {@rest}
        />
        <%= @label %>
      </label>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <select
        id={@id}
        name={@name}
        class={["block w-full mt-2 bg-white rounded-md shadow-sm sm:text-sm", ring_classes(@errors)]}
        multiple={@multiple}
        {@rest}
      >
        <option :if={@prompt} value=""><%= @prompt %></option>
        <%= Phoenix.HTML.Form.options_for_select(@options, @value) %>
      </select>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <textarea
        id={@id}
        name={@name}
        class={[
          "mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6",
          "min-h-[6rem]",
          ring_classes(@errors)
        ]}
        {@rest}
      ><%= Phoenix.HTML.Form.normalize_value("textarea", @value) %></textarea>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "radiogroup"} = assigns) do
    ~H"""
    <fieldset>
      <.label for={@id}><%= @label %></.label>

      <div class="flex flex-row flex-wrap gap-3 mt-4">
        <label
          :for={{{label, value}, idx} <- Enum.with_index(@options)}
          for={"#{@id}-#{idx}"}
          class={[
            "group flex items-center border border-zinc-600 justify-center px-3 py-3 text-sm font-semibold uppercase rounded-md cursor-pointer sm:flex-1",
            to_string(@value) == to_string(value) &&
              "bg-zinc-600 text-zinc-50",
            ring_classes(@errors)
          ]}
        >
          <input
            type="radio"
            name={@name}
            id={"#{@id}-#{idx}"}
            value={value}
            checked={to_string(@value) == to_string(value)}
            class="sr-only"
            aria-labelledby={"#{@id}-#{idx}-label"}
          />
          <span id={"#{@id}-#{idx}-label"}><%= label %></span>
        </label>
      </div>
    </fieldset>
    """
  end

  def input(assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={[
          "mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6",
          ring_classes(@errors)
        ]}
        {@rest}
      />
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  defp ring_classes(errors \\ []),
    do: [
      "focus:outline-none focus:border-zinc-300 focus:ring-2 focus:ring-zinc-800 focus:ring-offset-2 focus:ring-offset-white",
      "focus-within:outline-none focus-within:border-zinc-300 focus-within:ring-2 focus-within:ring-zinc-800 focus-within:ring-offset-2 focus-within:ring-offset-white",
      errors != [] &&
        "border-rose-600 focus-visible:ring-rose-600 focus-within:border-rose-600 focus-within:ring-rose-600"
    ]

  attr :for, :string, default: nil
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label for={@for} class="block text-sm font-semibold leading-6 text-zinc-800">
      <%= render_slot(@inner_block) %>
    </label>
    """
  end

  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="flex gap-3 mt-3 text-sm leading-6 text-rose-600 phx-no-feedback:hidden">
      <.icon name="hero-exclamation-circle-mini" class="mt-0.5 h-5 w-5 flex-none" />
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  attr :class, :string, default: nil

  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", @class]}>
      <div>
        <h1 class="text-lg font-semibold leading-8 text-zinc-800">
          <%= render_slot(@inner_block) %>
        </h1>
        <p :if={@subtitle != []} class="mt-2 text-sm leading-6 text-zinc-600">
          <%= render_slot(@subtitle) %>
        </p>
      </div>
      <div class="self-start flex-none"><%= render_slot(@actions) %></div>
    </header>
    """
  end

  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"
  slot :empty

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class="px-4 overflow-y-auto sm:overflow-visible sm:px-0">
      <%= if Enum.empty?(@rows) do %>
        <%= render_slot(@empty) %>
      <% else %>
        <table class="w-[40rem] mt-11 sm:w-full">
          <thead class="text-sm leading-6 text-left text-zinc-500">
            <tr>
              <th :for={col <- @col} class="p-0 pb-4 pr-6 font-normal"><%= col[:label] %></th>
              <th :if={@action != []} class="relative p-0 pb-4">
                <span class="sr-only"><%= "Actions" %></span>
              </th>
            </tr>
          </thead>
          <tbody
            id={@id}
            phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
            class="relative text-sm leading-6 border-t divide-y divide-zinc-100 border-zinc-200 text-zinc-700"
          >
            <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class="group hover:bg-zinc-50">
              <td
                :for={{col, i} <- Enum.with_index(@col)}
                phx-click={@row_click && @row_click.(row)}
                class={["relative p-0", @row_click && "hover:cursor-pointer"]}
              >
                <div class="block py-4 pr-6">
                  <span class="absolute right-0 -inset-y-px -left-4 group-hover:bg-zinc-50 sm:rounded-l-xl" />
                  <span class={["relative", i == 0 && "font-semibold text-zinc-900"]}>
                    <%= render_slot(col, @row_item.(row)) %>
                  </span>
                </div>
              </td>
              <td :if={@action != []} class="relative p-0 w-14">
                <div class="relative py-4 text-sm font-medium text-right whitespace-nowrap">
                  <span class="absolute left-0 -inset-y-px -right-4 group-hover:bg-zinc-50 sm:rounded-r-xl" />
                  <span
                    :for={action <- @action}
                    class="relative ml-4 font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
                  >
                    <%= render_slot(action, @row_item.(row)) %>
                  </span>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      <% end %>
    </div>
    """
  end

  slot :item do
    attr :title, :string, required: true
  end

  slot :empty

  def list(assigns) do
    ~H"""
    <div class="my-14">
      <dl class="-my-4 divide-y divide-zinc-100">
        <div :for={item <- @item} class="flex gap-4 py-4 text-sm leading-6 sm:gap-8">
          <dd class="text-zinc-700"><%= render_slot(item) %></dd>
        </div>
      </dl>
      <%= if Enum.empty?(@item) do %>
        <%= render_slot(@empty) %>
      <% end %>
    </div>
    """
  end

  attr :navigate, :any, required: true
  attr :class, :string, default: ""
  slot :inner_block, required: true

  def back(assigns) do
    ~H"""
    <div class={@class}>
      <.button
        phx-click={JS.navigate(@navigate)}
        class="text-sm font-semibold leading-6"
        variant="outline"
        size="icon"
      >
        <.icon name="hero-arrow-left-solid" class="w-3 h-3" />
      </.button>
    </div>
    """
  end

  attr :name, :string, required: true
  attr :class, :string, default: nil

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> show("##{id}-container")
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> hide("##{id}-container")
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end

  attr :stream, :any, required: true
  attr :stream_length, :integer, required: true

  def event_log(assigns) do
    ~H"""
    <ul id="event" phx-update="stream" phx-page-loading class="flex flex-col gap-6">
      <li :for={{id, event} <- @stream} id={id}>
        <.log_entry event={event} />
      </li>
    </ul>
    <div :if={@stream_length < 1} class="mt-5 text-base font-semibold text-center">
      Nothing has happened yet...
    </div>
    """
  end

  attr :event, :any, required: true
  attr :icon_name, :string

  defp log_entry(assigns) do
    ~H"""
    <div class="relative pb-8">
      <span class="absolute left-4 top-4 -ml-px h-full w-0.5 bg-gray-200" aria-hidden="true"></span>
      <div class="relative flex space-x-3">
        <div>
          <span class="flex items-center justify-center w-8 h-8 bg-gray-400 rounded-full ring-8 ring-white">
            <.icon name={@icon_name} class="w-5 h-5 text-white" />
          </span>
        </div>
        <div class="flex min-w-0 flex-1 justify-between space-x-4 pt-1.5">
          <div>
            <p class="text-sm text-gray-500"><%= truncate_event_struct(@event.__struct__) %></p>
            <span class="font-medium text-gray-900"><%= @event.raw_text %></span>
          </div>
          <div class="text-sm text-right text-gray-500 whitespace-nowrap">
            <time datetime="2020-09-20">Sep 20</time>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp truncate_event_struct(struct), do: struct |> Module.split() |> List.last()

  attr :orientation, :string, values: ~w(vertical horizontal), default: "horizontal"
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  def separator(assigns) do
    ~H"""
    <div
      class={[
        "shrink-0 bg-zinc-100",
        (@orientation == "horizontal" && "h-[1px] w-full") || "h-full w-[1px]",
        @class
      ]}
      {@rest}
    >
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def tooltip(assigns) do
    ~H"""
    <div
      class={[
        "relative group/tooltip inline-block",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  slot :inner_block, required: true

  def tooltip_trigger(assigns) do
    ~H"""
    <%= render_slot(@inner_block) %>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global
  attr :side, :string, default: "left"
  slot :inner_block, required: true

  def tooltip_content(assigns) do
    ~H"""
    <div
      class={[
        "tooltip-content absolute whitespace-nowrap hidden group-hover/tooltip:block top-full mt-2",
        "z-50 w-auto overflow-hidden rounded-md border bg-zinc-50 px-3 py-1.5 text-sm shadow-md animate-in fade-in-0 zoom-in-95 data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2",
        @side == "left" && "right-0",
        @side == "right" && "left-0",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </div>
    """
  end
end
