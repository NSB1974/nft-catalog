export function Button(props: any) {
  return (
    <button
      className={`${props.bgColor || 'bg-white'} ${
        props.hoverColor || 'hover:bg-gray-100'
      } ${
        props.textColor || 'text-gray-800'
      } font-semibold py-2 px-4 border border-gray-400 rounded shadow`}
      {...props}
    >
      {props.children}
    </button>
  );
}
