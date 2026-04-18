import { Layers3 } from "lucide-react";

interface StatusTileProps {
  icon: typeof Layers3;
  label: string;
  tone: "amber" | "blue" | "stone" | "emerald";
  value: string;
}

export function StatusTile(props: StatusTileProps) {
  const Icon = props.icon;
  const toneClass = {
    amber: "border-amber-200 bg-amber-50 text-amber-800",
    blue: "border-sky-200 bg-sky-50 text-sky-800",
    stone: "border-stone-200 bg-stone-50 text-stone-800",
    emerald: "border-emerald-200 bg-emerald-50 text-emerald-800"
  }[props.tone];

  return (
    <div className={`rounded-2xl border px-4 py-4 ${toneClass}`}>
      <div className="mb-3 inline-flex h-10 w-10 items-center justify-center rounded-xl bg-white/80 shadow-sm">
        <Icon className="h-5 w-5" />
      </div>
      <p className="text-xs font-medium uppercase tracking-[0.2em]">{props.label}</p>
      <p className="mt-2 line-clamp-2 text-sm font-semibold leading-6 text-stone-950">{props.value}</p>
    </div>
  );
}
